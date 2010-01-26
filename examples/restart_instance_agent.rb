#!/usr/bin/ruby
require 'rubygems'
require 'trollop'
require 'rest_connection'
require 'net/ssh'

opts = Trollop::options do
  opt :deployment, "deployment nickname", :type => :string, :required => true
  opt :only, "regex string matching the nickname of the servers you want to relaunch. This excludes servers that do not match\nExample --only ubuntu", :type => :string, :required => false
end

# find all servers in the deployment (the fast way)
deployment = Deployment.find_by_nickname_speed(opts[:deployment]).first
servers = deployment.servers_no_reload
servers = servers.select { |s| s.nickname =~ /#{opts[:only]}/ } if opts[:only]

servers.each do |s|
  s.wait_for_operational_with_dns
  s.spot_check("gem uninstall right_resources_premium") do |result|
    puts result
  end
  s.spot_check("monit restart instance") do |result|
    puts result
  end
end
