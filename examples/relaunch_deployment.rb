#!/usr/bin/ruby
require 'rubygems'
require 'trollop'
require 'rest_connection'

opts = Trollop::options do
  opt :deployment, "deployment nickname", :type => :string, :required => true
end

# find all servers in the deployment (the fast way)
deployment = Deployment.find_by_nickname_speed(opts[:deployment]).first
servers = deployment.servers
servers.each do |s|
  # force the server to populate it's state
  s.reload
  # send stop
  s.stop
end

# wait for termination
servers.each do |s|
  s.wait_for_state('stopped')
end

# relaunch
servers.each do |s|
  s.start
end
