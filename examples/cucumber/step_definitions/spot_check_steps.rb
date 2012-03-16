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

Then /^I should run a command "([^\"]*)" on server "([^\"]*)"\.$/ do |command, server_index|
  human_index = server_index.to_i - 1
  @servers[human_index].spot_check(command) { |result| puts result }
end

When /^I run "([^\"]*)"$/ do |command|
  @response = @server.spot_check_command?(command)
end

When /^I run "([^\"]*)" on all servers$/ do |command|
  @all_servers.each_with_index do |s,i|
    @all_responses[i] = s.spot_check_command?(command)
  end
end


#
# Checking for request sucess/error
#
Then /^it should exit successfully$/ do
  @response.should be true
end

Then /^it should exit successfully on all servers$/ do
  @all_responses.each do |response|
    response.should be true
  end
end

Then /^it should not exit successfully on any server$/ do
  @all_responses.each do |response|
    response.should_not be true
  end
end

