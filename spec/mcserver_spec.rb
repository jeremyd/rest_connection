require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe McServer, "server api object exercise" do
  before(:all) do
    @mcserver_v5 = McServer.find("/api/clouds/850/instances/AA5AOKVUOJPC9") # a v5 server
  end

  it "should run a recipe on a v5 server" do
    this_template = ServerTemplate.find(@mcserver_v5.server_template_href)
    run_first = this_template.executables.first
    audit = @mcserver_v5.run_executable(run_first)
    audit.wait_for_completed
  end
end
