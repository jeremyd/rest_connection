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

require 'rest_connection/rightscale/rightscale_api_base'
require 'rest_connection/rightscale/rightscale_api_internal'
require 'rest_connection/rightscale/rightscale_api_gateway'
require 'rest_connection/rightscale/rightscale_api_taggable'
require 'rest_connection/rightscale/rightscale_api_mc_taggable'
require 'rest_connection/rightscale/rightscale_api_mc_input'
require 'rest_connection/ssh_hax'
require 'rest_connection/rightscale/alert_spec_subject'
require 'rest_connection/rightscale/server_ec2_ebs_volume'
require 'rest_connection/rightscale/sqs_queue'
require 'rest_connection/rightscale/executable'
require 'rest_connection/rightscale/cloud_account'
require 'rest_connection/rightscale/server_internal'
require 'rest_connection/rightscale/server'
require 'rest_connection/rightscale/deployment'
require 'rest_connection/rightscale/status'
require 'rest_connection/rightscale/server_template_internal'
require 'rest_connection/rightscale/server_template'
require 'rest_connection/rightscale/instance'
require 'rest_connection/rightscale/ec2_security_group'
require 'rest_connection/rightscale/vpc_dhcp_option'
require 'rest_connection/rightscale/ec2_ssh_key_internal'
require 'rest_connection/rightscale/ec2_ssh_key'
require 'rest_connection/rightscale/tag'
require 'rest_connection/rightscale/mc_tag'
require 'rest_connection/rightscale/task'
require 'rest_connection/rightscale/backup'
require 'rest_connection/rightscale/mc_audit_entry'
require 'rest_connection/rightscale/rs_internal'
require 'rest_connection/rightscale/audit_entry'
require 'rest_connection/rightscale/alert_spec'
require 'rest_connection/rightscale/ec2_ebs_volume'
require 'rest_connection/rightscale/ec2_ebs_snapshot'
require 'rest_connection/rightscale/mc_volume_attachment'
require 'rest_connection/rightscale/mc_volume'
require 'rest_connection/rightscale/mc_volume_snapshot'
require 'rest_connection/rightscale/mc_volume_type'
require 'rest_connection/rightscale/mc_server'
require 'rest_connection/rightscale/server_interface'
require 'rest_connection/rightscale/mc_instance'
require 'rest_connection/rightscale/monitoring_metric'
require 'rest_connection/rightscale/session'
require 'rest_connection/rightscale/mc_multi_cloud_image_setting'
require 'rest_connection/rightscale/mc_multi_cloud_image'
require 'rest_connection/rightscale/mc_server_template_multi_cloud_image'
require 'rest_connection/rightscale/mc_server_template'
require 'rest_connection/rightscale/right_script_attachment_internal'
require 'rest_connection/rightscale/right_script_internal'
require 'rest_connection/rightscale/right_script'
require 'rest_connection/rightscale/multi_cloud_image_cloud_setting_internal'
require 'rest_connection/rightscale/multi_cloud_image_internal'
require 'rest_connection/rightscale/multi_cloud_image'
require 'rest_connection/rightscale/ec2_server_array'
require 'rest_connection/rightscale/mc_server_array'
require 'rest_connection/rightscale/security_group_rule'
require 'rest_connection/rightscale/mc_security_group'
require 'rest_connection/rightscale/mc_deployment'
require 'rest_connection/rightscale/mc_datacenter'
require 'rest_connection/rightscale/mc_ssh_key'
require 'rest_connection/rightscale/ec2_elastic_ip'
require 'rest_connection/rightscale/credential'
require 'rest_connection/rightscale/cloud'
require 'rest_connection/rightscale/instance_type'
require 'rest_connection/rightscale/mc_instance_type'
require 'rest_connection/rightscale/mc_image'
require 'rest_connection/rightscale/macro'
require 'rest_connection/rightscale/s3_bucket'
require 'rest_connection/rightscale/account'
require 'rest_connection/rightscale/child_account'
require 'rest_connection/rightscale/permission'
require 'rest_connection/rightscale/user'
