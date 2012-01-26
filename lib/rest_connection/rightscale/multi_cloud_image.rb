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
    some_settings = McMultiCloudImage.find(rs_id.to_i).get_settings
    internal = MultiCloudImageInternal.new("href" => self.href)
    internal.reload
    more_settings = internal.settings
    @params["multi_cloud_image_cloud_settings"] = some_settings + more_settings
  end

end
