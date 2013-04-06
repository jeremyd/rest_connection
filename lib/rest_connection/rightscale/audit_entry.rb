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


#class AuditEntry
#  attr_accessor :status, :output
#  def initialize(opts)
#    @status = opts[:status]
#    @output = opts[:output]
#  end
#  def wait_for_completed(audit_link = "no audit link available")
#    raise "FATAL: script failed. see audit #{audit_link}" unless @status
#  end
#end

#
# API 1.0
#
class AuditEntry
  include  RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  deny_methods :index, :create, :destroy, :update

  def wait_for_state(state, timeout=900)
    while(timeout > 0)
      reload
      return true if state == self.state
      connection.logger("state is #{self.state}, waiting for #{state}")
      friendly_url = "https://my.rightscale.com/audit_entries/"
      friendly_url += self.href.split(/\//).last
      raise "FATAL error, #{self.summary}\nSee Audit: API:#{self.href}, WWW:<a href='#{friendly_url}'>#{friendly_url}</a>\n" if self.state == 'failed'
      sleep 30
      timeout -= 30
    end
    raise "FATAL: Timeout waiting for Executable to complete.  State was #{self.state}" if timeout <= 0
  end

  def wait_for_completed(timeout=900)
    wait_for_state("completed", timeout)
  end
end
