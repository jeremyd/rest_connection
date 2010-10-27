require File.join(File.dirname(__FILE__), 'spec_helper')
require 'ruby-debug'

describe ServerTemplateInternal, "exercises the server_template internal api" do

  it "should do some stuff" do
    some_image_href = "https://moo.rightscale.com/api/acct/0/ec2_images/ami-0859bb61?cloud_id=1"
    @mci = MultiCloudImageInternal.create(:name => "123deleteme-test test 1234", :description => "woah")
    @new_setting = MultiCloudImageCloudSettingInternal.create(:multi_cloud_image_href => @mci.href, :cloud_id => 1, :ec2_image_href => some_image_href, :aws_instance_type => "m1.small")
    @new_st = ServerTemplate.create(:multi_cloud_image_href => @mci.href, :nickname => "123deleteme-test test 123456", :description => "1234")
    @executable = Executable.new('right_script' => {:href => "https://moo.rightscale.com/api/acct/2901/right_scripts/256669"})
    @st = ServerTemplateInternal.new(:href => @new_st.href)

    # Test commit
    @st.commit('hello commits world')

    # Test clone
    @clone = @new_st.clone
    @clone.reload

    # Test add_executable
    @st.add_executable(@executable, "boot")

    # Test delete_executable
    @st.delete_executable(@executable, "boot")
  end

  after(:all) do
    @new_st.destroy
    @mci.destroy
    @clone.destroy
  end
  

end
