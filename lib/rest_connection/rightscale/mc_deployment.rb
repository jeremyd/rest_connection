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
class McDeployment
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend
  include RightScale::Api::McTaggable
  extend RightScale::Api::McTaggableExtend
  include RightScale::Api::McInput

  def resource_plural_name
    "deployments"
  end

  def resource_singular_name
    "deployment"
  end

  def self.resource_plural_name
    "deployments"
  end

  def self.resource_singular_name
    "deployment"
  end

  def self.filters
    [:description, :name]
  end

  def self.create(opts)
    location = connection.post(resource_plural_name, opts)
    newrecord = self.new('href' => location)
    newrecord.show
    newrecord
  end

  def save
    inst_href = URI.parse(self.href)
    connection.put(inst_href.path, @params)
  end

  # TODO Add server method

  def destroy
    deploy_href = URI.parse(self.href)
    connection.delete(deploy_href.path)
  end
end
