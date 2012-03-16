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
require 'rest_connection'

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

    # test clone
    @new_mci_test = @mci2.clone

    # test commit
    @new_mci_test.commit("hello commits world")

  end

  after(:all) do
    @int_new_mci_test = MultiCloudImageInternal.new(:href => @new_mci_test.href)
    @new_st.destroy
    @mci.destroy
    @mci2.destroy
    @int_new_mci_test.destroy
  end
  

end
 
