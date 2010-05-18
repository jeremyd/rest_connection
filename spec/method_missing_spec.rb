require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe Server, "using a server" do
  before(:all) do
  end

  it "should use method_missing for assignment" do
    @server = Server.find(37842) # hardcoded, you must change to valid server in your account
    @server.max_spot_price = "0.01"
    @server.pricing = "spot"
    @server.save
    @server.max_spot_price.should == "0.01"
  end

end
