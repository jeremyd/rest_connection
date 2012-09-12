#--
# Copyright (c) 2010-2012 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'net/ssh'

# This is a mixin module run_recipes until api support is ready for checking result of recipe run.
# The mixin typically used from Server#run_recipe
module SshHax

  SSH_RETRY_COUNT = 3

  def ssh_key_config(item)
    if item.is_a?(Array)
      ssh_keys = item
    elsif item.is_a?(String)
      ssh_keys = [item]
    elsif k = connection.settings[:ssh_key]
      ssh_keys = [k]
    elsif kk = connection.settings[:ssh_keys]
      ssh_keys = kk
    else
      ssh_keys = nil
    end
    ssh_keys
  end

  def run_and_tail(run_this, tail_command, expect, ssh_key=nil, host_dns=self.reachable_ip)
    status = nil
    result = nil
    output = ""
    connection.logger("Running: #{run_this}")
    Net::SSH.start(host_dns, 'rightscale', :keys => ssh_key_config(ssh_key), :user_known_hosts_file => "/dev/null") do |ssh|
      cmd_channel = ssh.open_channel do |ch1|
        ch1.on_request('exit-status') do |ch, data|
          status = data.read_long
        end
        ch1.exec(run_this) do |ch2, success|
          unless success
            output = "ERROR: SSH cmd failed to exec"
            status = 1
          end
          ch2.on_data do |ch, data|
            output += data
          end
          ch2.on_extended_data do |ch, type, data|
            output += data
          end

        end
      end
      log_channel = ssh.open_channel do |ch2|
        ch2.exec tail_command do |ch, success|
          raise "could not execute command" unless success
          # "on_data" is called when the process writes something to stdout
          ch.on_data do |c, data|
            output += data
            if data =~ expect
              result = $1
            end
          end
          # "on_extended_data" is called when the process writes something to stderr
          ch.on_extended_data do |c, type, data|
            #STDERR.print data
          end
          ch.on_close do
          end
          ch.on_process do |c|
            if result
              ch.close
              ssh.exec("killall tail")
            end
          end
        end
      end
      cmd_channel.wait
      log_channel.wait
    end
    connection.logger output
    success = result.include?('completed')
    connection.logger "Converge failed. See server audit: #{self.audit_link}" unless success
    return {:status => success, :output => output}
  end

  # script is an Executable object with minimally nick or id set
  def run_executable_with_ssh(script, options={}, ssh_key=nil)
    raise "FATAL: run_executable called on a server with no reachable_ip. You need to run .settings on the server to populate this attribute." unless self.reachable_ip
    if script.is_a?(Executable)
      script = script.right_script
    end

    raise "FATAL: unrecognized format for script.  Must be an Executable or RightScript with href or name attributes" unless (script.is_a?(RightScript)) && (script.href || script.name)
    if script.href
      run_this = "rs_run_right_script -i #{script.href.split(/\//).last}"
    elsif script.name
      run_this = "rs_run_right_script -n #{script.name}"
    end
    tail_command ="tail -f -n1 /var/log/messages"
    expect = /RightLink.*RS> ([completed|failed]+:)/
    options.each do |key, value|
      run_this += " -p #{key}=#{value}"
    end
    AuditEntry.new(run_and_tail(run_this, tail_command, expect))
  end

  # recipe can be either a String, or an Executable
  # host_dns is optional and will default to objects self.reachable_ip
  def run_recipe_with_ssh(recipe, ssh_key=nil, host_dns=self.reachable_ip)
    raise "FATAL: run_script called on a server with no reachable_ip. You need to run .settings on the server to populate this attribute." unless self.reachable_ip
    if recipe.is_a?(Executable)
      recipe = recipe.recipe
    end
    tail_command ="tail -f -n1 /var/log/messages"
    expect = /RightLink.*RS> ([completed|failed]+: < #{recipe} >)/
    run_this = "rs_run_recipe -n '#{recipe}'"
    run_and_tail(run_this, tail_command, expect, ssh_key)
  end

  def spot_check(command, ssh_key=nil, host_dns=self.reachable_ip, &block)
    connection.logger "SSHing to #{host_dns}"
    Net::SSH.start(host_dns, 'rightscale', :keys => ssh_key_config(ssh_key)) do |ssh|
      result = ssh.exec!(command)
      yield result
    end
  end

  # returns true or false based on command success
  def spot_check_command?(command, ssh_key=nil, host_dns=self.reachable_ip)
    results = spot_check_command(command, ssh_key, host_dns)
    return results[:status] == 0
  end


  # returns hash of exit_status and output from command
  def spot_check_command(command, ssh_key=nil, host_dns=self.reachable_ip, do_not_log_result=false)
    raise "FATAL: spot_check_command called on a server with no reachable_ip. You need to run .settings on the server to populate this attribute." unless host_dns
    connection.logger "SSHing to #{host_dns} using key(s) #{ssh_key_config(ssh_key).inspect}"
    status = nil
    output = ""
    success = false
    retry_count = 0
    while (!success && retry_count < SSH_RETRY_COUNT) do
      begin
        # Test for ability to connect; Net::SSH.start sometimes hangs under certain server-side sshd configs
        test_ssh = ""
        [5, 15, 60].each { |timeout_max|
          test_ssh = `ssh -o \"BatchMode=yes\" -o \"StrictHostKeyChecking=no\" -o \"ConnectTimeout #{timeout_max}\" rightscale@#{host_dns} -C \"exit\" 2>&1`.chomp
          break if test_ssh =~ /permission denied/i or test_ssh.empty?
        }
        raise test_ssh unless test_ssh =~ /permission denied/i or test_ssh.empty?

        Net::SSH.start(host_dns, 'rightscale', :keys => ssh_key_config(ssh_key), :user_known_hosts_file => "/dev/null") do |ssh|
          cmd_channel = ssh.open_channel do |ch1|
            ch1.on_request('exit-status') do |ch, data|
              status = data.read_long
            end
            ch1.exec(command) do |ch2, success|
              unless success
                status = 1
              end
              ch2.on_data do |ch, data|
                output += data
              end
              ch2.on_extended_data do |ch, type, data|
                output += data
              end
            end
          end
        end
      rescue Exception => e
        retry_count += 1 # opening the ssh channel failed -- try again.
        connection.logger "ERROR during SSH session to #{host_dns}, retrying #{retry_count}: #{e} #{e.backtrace}"
        sleep 10
        raise e unless retry_count < SSH_RETRY_COUNT
      end
    end
    connection.logger "SSH Run: #{command} on #{host_dns}. Retry was #{retry_count}. Exit status was #{status}. Output below ---\n#{output}\n---" unless do_not_log_result
    return {:status => status, :output => output}
  end

end
