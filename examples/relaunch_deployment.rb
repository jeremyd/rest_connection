#!/usr/bin/ruby
require 'rubygems'
require 'trollop'
require 'rest_connection'

opts = Trollop::options do
  opt :deployment, "deployment nickname", :type => :string, :required => false
  opt :only, "regex string matching the nickname of the servers you want to relaunch. This excludes servers that do not match\nExample --only ubuntu", :type => :string, :required => false
  opt :id, "deployment id", :type => :string, :required => false
end

# find all servers in the deployment (the fast way)
if opts[:id]
  deployment = Deployment.find(opts[:id])
else
  deployment = Deployment.find_by_nickname_speed(opts[:deployment]).first
end
servers = deployment.servers_no_reload
servers = servers.select { |s| s.nickname =~ /#{opts[:only]}/ } if opts[:only]
servers.each do |s|
  s.stop
end
servers.each do |s|
  s.wait_for_state("stopped")
  s.start
end

