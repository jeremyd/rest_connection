require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe MultiCloudImageInternal, "exercises the mci internal api" do

  it "should do some stuff" do
    some_image_href = "https://moo1.rightscale.com/api/acct/0/ec2_images/ami-0859bb61?cloud_id=1"
    @mci = MultiCloudImageInternal.create(:name => "123deleteme-test test 1234", :description => "woah")
    @mci2 = MultiCloudImageInternal.create(:name => "1234deleteme-test test 12345", :description => "woah")
    @new_setting = MultiCloudImageCloudSettingInternal.create(:multi_cloud_image_href => @mci.href, :cloud_id => 1, :ec2_image_href => some_image_href, :aws_instance_type => "m1.small")

    @new_st = ServerTemplate.create(:multi_cloud_image_href => @mci.href, :nickname => "123deleteme-test test 123456", :description => "1234")

    @really_new_st = ServerTemplateInternal.new(:href => @new_st.href)
    @really_new_st.add_multi_cloud_image(@mci2.href)
    @really_new_st.set_default_multi_cloud_image(@mci2.href)
    trash = @really_new_st.multi_cloud_images
    trash.class.should == Array
    trash.first.class.should == Hash
    @really_new_st.delete_multi_cloud_image(@mci.href)
  end

  after(:all) do
    @new_st.destroy
    #@mci.destroy
    #@mci2.destroy
  end
  

end
 
