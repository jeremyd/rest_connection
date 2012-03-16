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
