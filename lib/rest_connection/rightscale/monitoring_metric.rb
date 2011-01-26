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
# You must have Beta v1.5 API access to use these internal API calls.
# 
class MonitoringMetric
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  def self.href(cloud_id, instance_id)
    "/clouds/#{cloud_id}/instances/#{instance_id}/#{self.resource_plural_name}"
  end

#  def self.find_all(cloud_id, instance_id)
#    a = Array.new
#    connection.get(self.href).each
#  end

  def show
    mm_href = URI.parse(self.href)
    @params.merge! connection.get(mm.path)
  end
end
