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

class MultiCloudImage
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  deny_methods :create, :destroy, :update

  def supported_cloud_ids
    @params["multi_cloud_image_cloud_settings"].map { |mcics| mcics.cloud_id }
  end

  # You must have access to multiple APIs for this (0.1, and 1.5)
  def find_and_flatten_settings()
    internal = MultiCloudImageInternal.new("href" => self.href)
    internal.reload
    total_image_count = internal.multi_cloud_image_cloud_settings.size
    # The .settings call filters out non-ec2 images
    more_settings = []
    if total_image_count > internal.settings.size
      more_settings = McMultiCloudImage.find(rs_id.to_i).get_settings
    end
    @params["multi_cloud_image_cloud_settings"] = internal.settings + more_settings
  end

end
