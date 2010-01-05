#!/usr/bin/ruby
require 'rubygems'
require 'trollop'
require 'rest_connection'
require 'net/ssh'

opts = Trollop::options do
  opt :deployment, "deployment nickname", :type => :string, :required => true
  opt :only, "regex string matching the nickname of the servers you want to relaunch. This excludes servers that do not match\nExample --only ubuntu", :type => :string, :required => false
  opt :growl, "use growl notification (string) when servers are all operational, requires ruby-growl gem", :type => :string, :required => false
end

# find all servers in the deployment (the fast way)
deployment = Deployment.find_by_nickname_speed(opts[:deployment]).first
servers = deployment.servers_no_reload
servers = servers.select { |s| s.nickname =~ /#{opts[:only]}/ } if opts[:only]

servers.each do |s|
  s.wait_for_state('operational')
end

puts "sleeping 20 just in case"
sleep 20 

servers.each do |s|
  s.reload
  Net::SSH.start(s.dns_name, 'root', :keys => ['~/.ssh/publish-test']) do |ssh|
    puts "setting up devmode: dropbox::install && devmode::setup_cookbooks"
    puts ssh.exec!("rs_run_recipe -n 'dropbox::install'")
    puts ssh.exec!("rs_run_recipe -n 'devmode::setup_cookbooks'")
  end
end

#if opts[:growl]
#  require 'ruby-growl'
#  servers.each do |s|
#    s.wait_for_state('booting')
#  end
#  g = Growl.new "localhost", "ruby-growl",
#              ["ruby-growl Notification"]
#g.notify "ruby-growl Notification", "It Came From Ruby-Growl",
#         "Greetings!"
#end
