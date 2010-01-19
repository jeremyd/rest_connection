require 'rubygems'
require 'spec'
require File.join(File.dirname(__FILE__), 'lib', 'right_scale_api_client')
require '/var/spool/ec2/user-data'

class Instance < RightScale::ApiClient::Base

  #def create_ebs_volume_from_snap(snap_aws_id)
  #  connection.post('create_ebs_volume.js', :aws_id => snap_aws_id )
  #end 

  def attach_ebs_volume(params)
    connection.put('attach_ebs_volume.js', params)
  end

  def create_ebs_snapshot(params)
    connection.post('create_ebs_snapshot.js', params)
  end

  def detach_ebs_volume(params)
    connection.put('detach_ebs_volume.js', params)
  end

  def delete_ebs_volume(params)
    connection.delete('delete_ebs_volume.js', params)
  end

  def create_ebs_volume(params)
    connection.post('create_ebs_volume.js', params)
  end
end

describe Instance, "run this from an ec2_instance" do
  before(:all) do
    @this_instance = Instance.new
    @this_instance.connection.settings[:api_url] = ENV['RS_API_URL']
    @this_instance.connection.settings[:common_headers] = { 'X_API_VERSION' => '1.0' }
    # when tests fail, we need this to ensure a fresh run
    x = @this_instance.detach_ebs_volume(:device => '/dev/sdp')
    sleep 10 if x
  end
  it "should create,attach,detach,delete an ebs_volume" do
    sleep 2
    result = @this_instance.create_ebs_volume({ 
                :nickname => "ebs_test_candelete#{rand(1000)}",
                :description => "created by ebs integration",
                :size => "1" })
    vol_aws_id = result['aws_id']
    vol_aws_id.should_not == nil
    @this_instance.attach_ebs_volume(:aws_id => result['aws_id'], :device => "/dev/sdp")
    sleep 10
    @this_instance.create_ebs_snapshot(:aws_id => vol_aws_id)
    sleep 5
    @this_instance.detach_ebs_volume(:device => '/dev/sdp')
    sleep 10
    @this_instance.delete_ebs_volume(:aws_id => vol_aws_id)
  end

end

=begin
#ROUTES REFERENCE GUIDE
 map.api_inst_resources 'ec2_instances', :member => { :find_latest_ebs_snapshot => :get,
                                                         :find_ebs_snapshots => :get, 
                                                         :create_ebs_volume_from_snap => :post, 
                                                         :create_ebs_volume => :post,
                                                         :delete_ebs_volume => :delete, 
                                                         :detach_ebs_volume => :put, 
                                                         :attach_ebs_volume => :put,
                                                         :cleanup_ebs_snapshots => :put,
                                                         :create_ebs_snapshot => :post,
                                                         :update_ebs_snapshot => :put,
                                                         :create_ebs_backup => :post,
                                                         :find_latest_ebs_backup => :get,
                                                         :cleanup_ebs_backups => :put,
                                                         :set_custom_lodgement => :put  # should we be using :post or :put ???
                                                       }
=end
