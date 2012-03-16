#!/usr/bin/env ruby

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

