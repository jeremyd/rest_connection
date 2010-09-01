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
#    For now this is a stub for using with the ssh enabled Server#run_script

#This is the v4 image only work status api.
# was used by Server#run_script (depricating..)
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
