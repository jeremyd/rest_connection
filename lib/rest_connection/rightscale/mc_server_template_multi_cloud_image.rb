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

class McServerTemplateMultiCloudImage
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :update

  def resource_plural_name
    "server_template_multi_cloud_images"
  end

  def resource_singular_name
    "server_template_multi_cloud_image"
  end

  def self.resource_plural_name
    "server_template_multi_cloud_images"
  end

  def self.resource_singular_name
    "server_template_multi_cloud_image"
  end

  def self.filters
    [:is_default, :multi_cloud_image_href, :server_template_href]
  end

  def make_default
    my_href = URI.parse(self.href)
    connection.post(my_href + "/make_default")
  end
end
