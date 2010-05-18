require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe ServerInternal, "server internal api object exercise" do
  before(:all) do
  end

  it "should find an internal server" do
    @server = Server.find(745582)
#    @server.start
#    @server.wait_for_state("operational")
    @server.stop_ebs
    @server.wait_for_state("stopped")
    @server.start_ebs
  end

end
