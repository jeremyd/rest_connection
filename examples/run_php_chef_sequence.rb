#!/usr/bin/ruby
require 'rubygems'
require 'trollop'
require 'rest_connection'
require 'net/ssh'

def run_recipe(recipe, host_dns, continue=false)
  STDOUT.puts "sshing to #{host_dns}"
  result = nil
  tail_command ="tail -f -n1 /var/log/messages"
  expect = /RightLink.*RS> ([completed|failed]+: < #{recipe} >)/

  Net::SSH.start(host_dns, 'root', :keys => ['~/.ssh/publish-test']) do |ssh|
    STDOUT.puts ssh.exec!("rs_run_recipe -n '#{recipe}'")
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
    log_channel.wait
  end
  raise "FATAL: halting execution, script #{result}" if result.include?('failed') && continue == false
  return result
end

def spot_check(command, host_dns, &block)
  Net::SSH.start(host_dns, 'root', :keys => ['~/.ssh/publish-test']) do |ssh|
    result = ssh.exec!(command)
    yield result
  end
end

opts = Trollop::options do
  opt :deployment, "deployment nickname", :type => :string, :required => false
  opt :id, "deployment id", :type => :string, :required => false
  opt :only, "regex string matching the nickname of the servers you want to relaunch. This excludes servers that do not match\nExample --only ubuntu", :type => :string, :required => false
end
if opts[:id]
  deployment = Deployment.find_by_id(opts[:id])
else
  deployment = Deployment.find_by_nickname_speed(opts[:deployment]).first
end
servers = deployment.servers_no_reload
servers = servers.select { |s| s.nickname =~ /#{opts[:only]}/ } if opts[:only]

raise "need at least 4 servers to start, only have: #{servers.size}" if servers.size < 4
# wait for servers to be ready
servers.each do |s|
  while(1)
    puts "waiting for dns-name for #{s.nickname}"
    break if s['dns-name'] && !s['dns-name'].empty?
    s.reload
   sleep 2
  end
  puts "DNS: #{s['dns-name']}"

  s.wait_for_state('operational')
end  

servers.each do |s|
  puts run_recipe("lb_haproxy::do_attach_request", s.dns_name)
end
sleep 20

a_frontend = servers.detect {|d| d.nickname.include?("FE")}
a_frontend.reload
raise "couldn't find a frontend with FE in the nickname!" unless a_frontend
puts a_frontend.dns_name
spot_check("cat /home/haproxy/rightscale_lb.cfg |grep server|grep -v '#'|wc -l", a_frontend.dns_name) do |result|
  puts "found attached servers: #{result}"
  raise "not enough servers #{result}" unless result.to_i == 4
end

servers.each do |s|
  run_recipe("app_php::do_update_code", s.dns_name)
end

servers.each do |s|
  run_recipe("lb_haproxy::do_detach_request", s.dns_name)
end
sleep 20
spot_check("cat /home/haproxy/rightscale_lb.cfg |grep server|grep -v '#'|wc -l", a_frontend.dns_name) do |result|
  puts "found attached servers: #{result}"
  raise "should be zero servers but was #{result}" unless result.to_i == 0
end


