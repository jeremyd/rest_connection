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

class MultiCloudImageInternal
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Internal
  extend RightScale::Api::InternalExtend

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

  def commit(message)
    t = URI.parse(self.href)
    MultiCloudImage.new(:href => connection.post(t.path + "/commit"))
  end

  def clone
    t = URI.parse(self.href)
    MultiCloudImage.new(:href => connection.post(t.path + "/clone"))
  end

  def transform_settings
    if @params["multi_cloud_image_cloud_settings"] && @params["multi_cloud_image_cloud_settings"].first.is_a?(Hash)
      @params["multi_cloud_image_cloud_settings"].map! { |setting|
        # Have to reject because API0.1 returns all clouds
        next if setting["fingerprint"] || setting["cloud_id"] > 10
        MultiCloudImageCloudSettingInternal.new(setting)
      }
      @params["multi_cloud_image_cloud_settings"].compact!
    end
  end

  def initialize(params={})
    @params = params
  end

  def settings
    transform_settings
    @params["multi_cloud_image_cloud_settings"]
  end

  def supported_cloud_ids
    @params["multi_cloud_image_cloud_settings"].map { |mcics| mcics.cloud_id }
  end
end
