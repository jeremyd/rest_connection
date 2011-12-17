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
class McMultiCloudImageSetting
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :create, :destroy, :update

  def resource_plural_name
    "settings"
  end

  def resource_singular_name
    "setting"
  end

  def self.resource_plural_name
    "settings"
  end

  def self.resource_singular_name
    "setting"
  end

  def self.parse_args(multi_cloud_image_id)
    "multi_cloud_images/#{multi_cloud_image_id}/"
  end

  def self.filters
    [:cloud_href, :multi_cloud_image_href]
  end

  def cloud_id
    self.cloud.split(/\//).last.to_i
  end
end
