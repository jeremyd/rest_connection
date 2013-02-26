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



  def spot_check(command, ssh_key=nil, host_dns=self.reachable_ip, &block)
    puts "SshHax::Probe method #{__method__}() entered..."
    results = spot_check_command(command, ssh_key, host_dns)
    yield results[:output]
  end



  # returns true or false based on command success
  def spot_check_command?(command, ssh_key=nil, host_dns=self.reachable_ip)
    puts "SshHax::Probe method #{__method__}() entered..."
    results = spot_check_command(command, ssh_key, host_dns)
    return results[:status] == 0
  end



  # returns hash of exit_status and output from command
  # Note that "sudo" is prepended to <command> and the 'rightscale' user is used.
  def spot_check_command(command, ssh_key=nil, host_dns=self.reachable_ip, do_not_log_result=false)
    puts "SshHax::Probe method #{__method__}() entered..."
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
          test_ssh = `ssh -ttq -o \"BatchMode=yes\" -o \"StrictHostKeyChecking=no\" -o \"ConnectTimeout #{timeout_max}\" rightscale@#{host_dns} -C \"exit\" 2>&1`.chomp
          break if test_ssh =~ /permission denied/i or test_ssh.empty?
        }
        raise test_ssh unless test_ssh =~ /permission denied/i or test_ssh.empty?

        Net::SSH.start(host_dns, 'rightscale', :keys => ssh_key_config(ssh_key), :user_known_hosts_file => "/dev/null") do |ssh|
          cmd_channel = ssh.open_channel do |ch1|
            ch1.on_request('exit-status') do |ch, data|
              status = data.read_long
            end
            # Request a pseudo-tty, this is needed as all calls use sudo to support RightLink 5.8
            ch1.request_pty do |ch, success|
              raise "Could not obtain a pseudo-tty!" if !success
            end
            # Now execute the command with "sudo" prepended to it.
            # NOTE: The use of single quotes is required to keep Ruby from interpretting the command string passed in and messing up regex's
            sudo_command = 'sudo ' + command
            puts 'SshHax::Probe executing ' + sudo_command + '...'
            ch1.exec(sudo_command) do |ch2, success|
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
    puts "SshHax::Probe method #{__method__}() exiting..."
    return {:status => status, :output => output}
  end

end
