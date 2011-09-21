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

  def self.parse_args(cloud_id, instance_id)
    "clouds/#{cloud_id}/instances/#{instance_id}/"
  end

  def data(start_time = "-60", end_time = "0")
    params = {'start' => start_time.to_s, 'end' => end_time.to_s}
    monitor = connection.get(URI.parse(self.href).path + "/data", params)
    # NOTE: The following is a dirty hack
    monitor['data'] = monitor['variables_data'].first
    monitor['data']['value'] = monitor['data']['points']
    monitor
  end
end
