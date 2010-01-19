#!/usr/bin/ruby
require 'rubygems'
require 'trollop'
require File.join(File.dirname(__FILE__), '..', 'lib', 'rightscale_api_resources')

#
# EBS regression test
# 
# prerequirements: run the macro for EBS stripe deployment
# enter the deployment name below
#

opts = Trollop::options do
  opt :deployment, "deployment nickname", :type => :string, :required => true
end

ebs_deployment = Deployment.find_by_nickname_speed(opts[:deployment]).first
# select servers by nickname!
mysql_s3 = ebs_deployment.servers.detect { |s| s.nickname =~ /MySQL S3 US db1/i }
mysql_db1 = ebs_deployment.servers.detect { |s| s.nickname =~ /MySQL EBS db1/i }
mysql_db2 = ebs_deployment.servers.detect { |s| s.nickname =~ /MySQL EBS Stripe db1/i }
mysql_db3 = ebs_deployment.servers.detect { |s| s.nickname =~ /MySQL EBS Stripe db2/i }

# we must reload, so the server can populate it's state
mysql_s3.reload
mysql_db1.reload
mysql_db2.reload
mysql_db3.reload

# stop all
mysql_s3.stop
mysql_db1.stop
mysql_db2.stop
mysql_db3.stop

# wait for stopped
mysql_s3.wait_for_state('stopped')
mysql_db1.wait_for_state('stopped')
mysql_db2.wait_for_state('stopped')
mysql_db3.wait_for_state('stopped')
