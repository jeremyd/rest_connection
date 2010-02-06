#    This file is part of RestConnection 
#
#    RestConnection is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    RestConnection is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with RestConnection.  If not, see <http://www.gnu.org/licenses/>.

# This is a helper to run_recipes, until api support is ready for checking result of recipe run.

require 'net/ssh'

module SshHax
  def run_recipe(recipe, ssh_key='~/.ssh/publish-test', host_dns=self.dns_name, continue=false)
    status = nil
    result = nil
    output = ""
    tail_command ="tail -f -n1 /var/log/messages"
    expect = /RightLink.*RS> ([completed|failed]+: < #{recipe} >)/
    run_this = "rs_run_recipe -n '#{recipe}'"
    Net::SSH.start(host_dns, 'root', :keys => [ssh_key]) do |ssh|
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
    success = result.include?('completed')
    connection.logger output
    connection.logger "Converge failed. See server audit: #{self.audit_link}" unless success
    return {:status => success, :output => output}
  end

  def spot_check(command, ssh_key="~/.ssh/publish-test", host_dns=self.dns_name, &block)
    connection.logger "SSHing to #{host_dns} using key #{ssh_key}"
    Net::SSH.start(host_dns, 'root', :keys => [ssh_key]) do |ssh|
      result = ssh.exec!(command)
      yield result
    end
  end 

  # returns true or false based on command success
  def spot_check_command?(command, ssh_key="~/.ssh/publish-test", host_dns=self.dns_name)
    results = spot_check_command(command, ssh_key, host_dns)
    return results[:status] == 0
  end


  # returns hash of exit_status and output from command
  def spot_check_command(command, ssh_key="~/.ssh/publish-test", host_dns=self.dns_name)
    connection.logger "SSHing to #{host_dns} using key #{ssh_key}"
    status = nil
    output = ""
    Net::SSH.start(host_dns, 'root', :keys => [ssh_key]) do |ssh|
      cmd_channel = ssh.open_channel do |ch1|
        ch1.on_request('exit-status') do |ch, data|
          status = data.read_long
        end
        output += "Running: #{command}\n"
        ch1.exec(command) do |ch2, success|
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
    end
    connection.logger output
    return {:status => status, :output => output}
  end 

end


