require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe MultiCloudImageInternal, "exercises the mci internal api" do

  it "should do some stuff" do
    some_image_href = "https://moo1.rightscale.com/api/acct/0/ec2_images/ami-0859bb61?cloud_id=1"
    some_st_id = 59180
    @mci = MultiCloudImageInternal.create(:name => "123deleteme-test test 1234", :description => "woah")
    @new_setting = MultiCloudImageCloudSettingInternal.create(:multi_cloud_image_href => @mci.href, :cloud_id => 1, :ec2_image_href => some_image_href, :aws_instance_type => "m1.small")

    #@new_st = ServerTemplate.find(some_st_id)
    @new_st = "/api/acct/2901/server_templates/59180"

    @really_new_st = ServerTemplateInternal.new(:href => @new_st)
    @really_new_st.add_multi_cloud_image(@mci.href)
    @really_new_st.set_default_multi_cloud_image(@mci.href)
    @really_new_st.multi_cloud_images
    @really_new_st.delete_multi_cloud_image(@mci.href)
  end

  after(:all) do
    #@mci.destroy
    #@new_st.destroy
  end
  

end
 
