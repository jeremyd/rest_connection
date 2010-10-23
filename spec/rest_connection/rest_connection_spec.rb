require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe RestConnection::Connection, " on_error callback test" do

  it "should register my on_error callback hook" do
    con = RestConnection::Connection.new()
    
    # mock the api call
    response = mock("Net::HTTPResponse", :code => "503", :body => "Mock Fail")
    con.should_receive(:call_api).and_return([response,"Fail"])
    
    # hook-up my own API exception handler
    con.on_error do |e|
      puts "I caught my exception! => (Msg: #{e.message})"
    end
    
    lambda { con.get("badrobot") }.should_not raise_error(Exception)  
  end

end 