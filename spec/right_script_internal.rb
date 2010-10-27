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
