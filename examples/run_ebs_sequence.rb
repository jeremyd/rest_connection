#!/usr/bin/ruby
require 'rubygems'
require 'trollop'
require 'rest_connection'
#
# EBS regression test
# 
# prerequirements: run the macro for EBS stripe deployment
# enter the deployment name below
#

opts = Trollop::options do
  opt :deployment, "deployment nickname", :type => :string, :required => true
end

#ebs_deployment = Deployment.find_by_nickname_speed("Regression Test - MySQL -STRIPE").first
ebs_deployment = Deployment.find_by_nickname_speed(opts[:deployment]).first

# select servers by nickname!
mysql_s3 = ebs_deployment.servers.detect { |s| s.nickname =~ /MySQL S3 US db1/i }
mysql_db1 = ebs_deployment.servers.detect { |s| s.nickname =~ /MySQL EBS db1/i }
mysql_db2 = ebs_deployment.servers.detect { |s| s.nickname =~ /MySQL EBS Stripe db1/i }
mysql_db3 = ebs_deployment.servers.detect { |s| s.nickname =~ /MySQL EBS Stripe db2/i }

# we must reload, so the server can populate it's state.  we took a shortcut
# by grabbing the servers from the deployment's json (the rightscale default response)
mysql_s3.reload
mysql_db1.reload
mysql_db2.reload
mysql_db3.reload

# tweak: (this is closer to an actual user story) setup mysql_db1 for regular EBS
# the rest of the deployment is normally set to text:2
# mysql_db1 is [rev 13] so it needs the old input name

#mysql_db1.set_input("OPT_EBS_STRIPE_COUNT", "ignore:$ignore")
#mysql_db1.set_input("DB_EBS_PREFIX", "text:shouldnotmatter-candelete652")
#mysql_db1.set_input("DB_LINEAGE_NAME", "text:shouldnotmatter-candelete652")
#mysql_db2.set_input("DB_LINEAGE_NAME", "text:shouldnotmatter-candelete652")
#mysql_db3.set_input("DB_LINEAGE_NAME", "text:shouldnotmatter-candelete652")

# launch all
mysql_s3.start
mysql_db1.start
mysql_db2.start
mysql_db3.start

# wait for operational
mysql_s3.wait_for_state('operational')
mysql_db1.wait_for_state('operational')
mysql_db2.wait_for_state('operational')
mysql_db3.wait_for_state('operational')

sleep 10 #make sure they are operational

# we need better api support, but for now we can get our RightScripts from info.yml on an instance (or in the current dir)
template_scripts = RightScript.from_instance_info

# scripts from EBS [rev13]
slave_init_non_ebs_rev4 = RightScript.new('href' => 'right_scripts/45320')
slave_init_non_ebs_v1_rev6 = RightScript.new('href' => 'right_scripts/41484')
restore_rev4 = RightScript.new('href' => 'right_scripts/45319')

# see how easy this is to cherry pick the scripts by name? this means no resetting of ids across different templates
restore_script = template_scripts.detect { |script| script.name =~ /restore/i }
slave_init_non_ebs = template_scripts.detect { |script| script.name =~ /DB EBS slave init from non-EBS master v1/ }
slave_init_non_stripe = template_scripts.detect { |script| script.name =~ /DB EBS stripe slave init from EBS non-stripe master/i }
promote = template_scripts.detect { |script| script.name =~ /promote/i }
slave_init = template_scripts.detect { |script| script.name == "DB EBS slave init (Stripe alpha)" }
backup = template_scripts.detect { |script| script.name =~ /DB EBS backup/i }

# breathing room is needed below *only to let the servers
# settle after fail-over operations. wait_for_completed returns
# when the right_script status is 'success' or 'fail'

status = mysql_db1.run_script(slave_init_non_ebs_v1_rev6)
status = mysql_db1.run_script(slave_init_non_ebs_rev4)
status.wait_for_completed(mysql_db1.audit_link)
sleep 220 #breathing room

status = mysql_db1.run_script(promote)
status.wait_for_completed(mysql_db1.audit_link)
sleep 220 #breathing room

status = mysql_db2.run_script(slave_init_non_stripe)
status.wait_for_completed(mysql_db2.audit_link)
sleep 220 # breathing room

status = mysql_db2.run_script(promote)
status.wait_for_completed(mysql_db2.audit_link)
sleep 220 #breathing room

status = mysql_db3.run_script(slave_init)
status.wait_for_completed(mysql_db3.audit_link)
puts "done!"
