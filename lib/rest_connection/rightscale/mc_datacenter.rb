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
class McDatacenter
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  def resource_plural_name
    "datacenters"
  end

  def resource_singular_name
    "datacenter"
  end

  def self.resource_plural_name
    "datacenters"
  end

  def self.resource_singular_name
    "datacenter"
  end

  def self.parse_args(cloud_id)
    "clouds/#{cloud_id}/"
  end

  def self.filters
    [:name, :resource_uid]
  end

  def show
    inst_href = URI.parse(self.href)
    @params.merge! connection.get(inst_href.path, 'view' => "full")
  end

  def save
    inst_href = URI.parse(self.href)
    connection.put(inst_href.path, @params)
  end

end
