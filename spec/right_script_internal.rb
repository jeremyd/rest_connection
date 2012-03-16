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

describe RightScriptInternal, "exercises the right_script internal api" do

  it "should do some stuff" do
    @some_script = RightScriptInternal.new(:href => "https://my.rightscale.com/api/acct/2901/right_scripts/256669")

    # Test commit
    @some_script.commit("hello commits world")

    # Test clone
    @new_script = @some_script.clone

    # Test update
    @same_script = RightScriptInternal.new(:href => @new_script.href)
    @same_script.name = "newname123"
    @same_script.save

  end

  after(:all) do
    # can't cleanup, don't have destroy calls
    #@new_script.destroy
  end
  

end
