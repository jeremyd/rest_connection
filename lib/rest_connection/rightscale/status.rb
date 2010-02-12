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

class Status < RightScale::Api::Base
  def wait_for_completed(audit_link = "no audit link available")
    while(1)
      reload
      return true if self.state == "completed"
      raise "FATAL error, script failed\nSee Audit: #{audit_link}" if self.state == 'failed'
      sleep 5
      connection.logger("querying status of right_script.. got: #{self.state}")
    end
  end
end
