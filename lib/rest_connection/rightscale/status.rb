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

#
#    For now this is a stub for using with the ssh enabled Server#run_script

#This is the v4 image only work status api.
# was used by Server#run_script (depricating..)
#
# API 1.0
#
class Status
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  def wait_for_completed(audit_link = "no audit link available", timeout = 900)
    while(timeout > 0)
      reload
      return true if self.state == "completed"
      raise "FATAL error, script failed\nSee Audit: #{audit_link}" if self.state == 'failed'
      sleep 30
      timeout -= 30
      connection.logger("querying status of right_script.. got: #{self.state}")
    end
    raise "FATAL: Timeout waiting for Executable to complete.  State was #{self.state}" if timeout <= 0
  end
end
