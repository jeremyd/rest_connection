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
class McMultiCloudImage
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend
  include RightScale::Api::McTaggable
  extend RightScale::Api::McTaggableExtend
  attr_reader :settings

  def resource_plural_name
    "multi_cloud_images"
  end

  def resource_singular_name
    "multi_cloud_image"
  end

  def self.resource_plural_name
    "multi_cloud_images"
  end

  def self.resource_singular_name
    "multi_cloud_image"
  end

  def self.parse_args(server_template_id=nil)
    server_template_id ? "server_templates/#{server_template_id}/" : ""
  end

  def self.filters
    [:description, :name, :revision]
  end

  def supported_cloud_ids
    @settings.map { |mcics| mcics.cloud_id }
  end

  def get_settings
    @settings = []
    url = URI.parse(self.href)
    connection.get(url.path + '/settings').each { |s|
      @settings << McMultiCloudImageSetting.new(s)
    }
    @settings
  end
end
