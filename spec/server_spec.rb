require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe Server, "server api object exercise" do
  before(:all) do
    @server_v4_right_script = Server.find(752616) # a v4 server
    @server_v5_recipe = Server.find(697640) # a v5 server
    @server_v5_right_script = Server.find() # a v5 server
  end

  it "should run a right_script on a v4 server" do
    this_template = ServerTemplate.find(@server_v4_right_script.server_template_href)
    run_first = this_template.executables.first
    location = @server_v4_right_script.run_executable(run_first)
    audit = AuditEntry.new(:href => location)
    audit.wait_for_completed
  end

  it "should run a recipe on a v5 server" do
    this_template = ServerTemplate.find(@server_v5_recipe.server_template_href)
    run_first = this_template.executables.first
    audit = @server_v5_recipe.run_executable(run_first)
    audit.wait_for_completed
  end

  it "should run a right_script on a v5 server" do
    this_template = ServerTemplate.find(@server_v5_right_script.server_template_href)
    run_first = this_template.executables.first
    audit = @server_v5_right_script.run_executable(run_first)
    audit.wait_for_completed
  end
end
