require 'rubygems'
require 'rest_connection'
require 'spec'
require 'ruby-debug'

describe Ec2SshKeyInternal, "ec2_ssh_key internal api object exercise" do
  before(:all) do
  end

  it "should find an index of all ssh keys" do
    all_keys = Ec2SshKeyInternal.find(:all)
    all_keys.empty?.should == false

    default_key = Ec2SshKeyInternal.find_by(:aws_key_name) {|n| n=~ /default/}
    default_key.first.should_not == nil

    default_key.first.href.should_not == nil
  end

end
