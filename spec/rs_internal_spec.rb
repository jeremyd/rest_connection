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
require 'ruby-debug'

describe RsInternal, "exercises the rs_internal api" do
  before(:all) do
    @st = ServerTemplate.find(27418)
  end

# this will never be checked in, these tests are too hardwired
# (doesn't mean it's not useful)
  it "should get all the mcis for this hardcoded template and set this hardcoded server" do
    mcis = RsInternal.get_server_template_multi_cloud_images(@st.href)
    mcis.empty?.should_not == true
    mcis.first['href'].include?("https://").should == true

    server = "/servers/752944"
    success = RsInternal.set_server_multi_cloud_image(server, mcis.first['href'])

    debugger
    puts "blah"

  end

end
