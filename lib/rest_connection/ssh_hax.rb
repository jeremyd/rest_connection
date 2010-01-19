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

module SshHax
  def run_recipe(recipe, ssh_key='~/.ssh/publish-test', host_dns=self.dns_name, continue=false)
    result = nil
    tail_command ="tail -f -n1 /var/log/messages"
    expect = /RightLink.*RS> ([completed|failed]+: < #{recipe} >)/

    Net::SSH.start(host_dns, 'root', :keys => ['']) do |ssh|
      cmd_channel = ssh.open_channel do |ch1|
        exec_helper("rs_run_recipe -n '#{recipe}'", ch1)
      end
      log_channel = ssh.open_channel do |ch|
        ch.exec tail_command do |ch, success|
          raise "could not execute command" unless success
          # "on_data" is called when the process writes something to stdout
          ch.on_data do |c, data|
            STDOUT.print data
            if data =~ expect
              STDOUT.puts "FOUND EXPECTED DATA, closing channel"
              result = $1
            end
          end
          # "on_extended_data" is called when the process writes something to stderr
          ch.on_extended_data do |c, type, data|
            STDERR.print data
          end
          ch.on_close do 
            STDOUT.puts "closed channel" 
          end
          ch.on_process do |c|
            if result
              STDOUT.puts "attempting close"
              ch.close
              ssh.exec("killall tail")
            end
          end
        end
      end 
      cmd_channel.wait
      log_channel.wait
    end
    raise "FATAL: halting execution, script #{result}" if result.include?('failed') && continue == false
    return result
  end

# this is a blocking call that will return the exit status of the command
  def exec_helper(command, chan, continue=false)
    STDOUT.puts "Running: #{command}"
    STDOUT.puts chan.exec(command)
    chan.wait
    status = chan.exec('echo "$?"')
    chan.wait
    ex = status.to_i
    raise "FATAL: could not run #{command}" if ex != 0 && continue == false
    ex
  end

end


