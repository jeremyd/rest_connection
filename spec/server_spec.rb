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
