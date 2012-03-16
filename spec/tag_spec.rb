require 'rubygems'
require 'rest_connection'
require 'ruby-debug'

describe Tag, "tags" do
  it "a server" do
    mytags = ["provides:rs_blah=blah"]
    search = ["provides:rs_blah"]
    #mytags = ["blah", "blah2"]
    s = Server.find(:first)
    t = Tag.set(s.href, mytags)
    t.response.code.should == "204"
    f = Tag.search("server", mytags)
    f.size.should > 0
    t2 = Tag.unset(s.href, mytags) 
    t2.response.code.should == "204"
  end
end
