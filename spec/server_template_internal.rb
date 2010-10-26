require 'rubygems'
require 'rest_connection'
require 'spec'

describe ServerTemplateInternal, "exercises the server_template internal api" do

  it "should do some stuff" do
    some_image_href = "https://moo.rightscale.com/api/acct/0/ec2_images/ami-0859bb61?cloud_id=1"
    @mci = MultiCloudImageInternal.create(:name => "123deleteme-test test 1234", :description => "woah")
    @new_setting = MultiCloudImageCloudSettingInternal.create(:multi_cloud_image_href => @mci.href, :cloud_id => 1, :ec2_image_href => some_image_href, :aws_instance_type => "m1.small")
    @new_st = ServerTemplate.create(:multi_cloud_image_href => @mci.href, :nickname => "123deleteme-test test 123456", :description => "1234")
    @st = ServerTemplateInternal.new(:href => @new_st.href)

    @st.commit('hello commits world')

    
  end

  after(:all) do
    @new_st.destroy
    @mci.destroy
  end
  

end
 
