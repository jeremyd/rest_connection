require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe MultiCloudImage do
  it "goes" do

    mci = MultiCloudImage.find(46563)
    mci = MultiCloudImage.find(57499)
    settings = mci.find_and_flatten_settings
    debugger
puts "blah"

  end
end
