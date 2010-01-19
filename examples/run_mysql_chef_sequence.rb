#!/usr/bin/ruby
require 'rubygems'
require 'trollop'
require 'rest_connection'
require 'net/ssh'

opts = Trollop::options do
  opt :deployment, "deployment nickname", :type => :string, :required => false
  opt :only, "regex string matching the nickname of the servers you want to relaunch. This excludes servers that do not match\nExample --only ubuntu", :type => :string, :required => false
  opt :id, "deployment id", :type => :string, :required => false
end

# find all servers in the deployment (the fast way)
if opts[:id]
  deployment = Deployment.find_by_id(opts[:id])
else
  deployment = Deployment.find_by_nickname_speed(opts[:deployment]).first
end
servers = deployment.servers_no_reload
servers = servers.select { |s| s.nickname =~ /#{opts[:only]}/ } if opts[:only]

raise "need at least 2 servers to start, only have: #{servers.size}" if servers.size < 2

# wait for servers to be ready
servers.each do |s|
  s.start
  while(1)
    puts "waiting for dns-name for #{s.nickname}"
    break if s['dns-name'] && !s['dns-name'].empty?
    s.reload
    sleep 2
  end
  puts "DNS: #{s['dns-name']}"

  s.wait_for_state('operational')
end  

servers[0].run_recipe("db_mysql::do_restore")
servers[0].run_recipe("db_mysql::setup_admin_privileges")
servers[0].run_recipe("db_mysql::do_backup")
servers[0].run_recipe("db_mysql::do_tag_as_master")

sleep(2)

servers[1].run_recipe("db_mysql::do_init_slave")
servers[1].run_recipe("db_mysql::do_promote_to_master")
