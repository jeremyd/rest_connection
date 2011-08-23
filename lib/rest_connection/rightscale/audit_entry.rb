#    This file is part of RestConnection 
#
#    RestConnection is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    RestConnection is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with RestConnection.  If not, see <http://www.gnu.org/licenses/>.
#
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

class AuditEntry
  include  RightScale::Api::Base
  extend RightScale::Api::BaseExtend

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
