require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe Tag, "tags" do
  it "a server" do
    mytags = ["provides:rs_blah=blah"]
    s = Server.find(37842)
    t = Tag.set(s.href, mytags)
    #f = Tag.search("server", mytags)
    t = Tag.unset(s.href, mytags) 
    
  end
end
