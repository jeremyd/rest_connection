require 'rubygems'
require 'rest_connection'
require 'spec'
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
