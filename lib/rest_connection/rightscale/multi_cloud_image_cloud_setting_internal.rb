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

class MultiCloudImageCloudSettingInternal
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Internal
  extend RightScale::Api::InternalExtend

  deny_methods :index, :show, :update

  def resource_plural_name
    "multi_cloud_image_cloud_settings"
  end

  def resource_singular_name
    "multi_cloud_image_cloud_setting"
  end

  def self.resource_plural_name
    "multi_cloud_image_cloud_settings"
  end

  def self.resource_singular_name
    "multi_cloud_image_cloud_setting"
  end

  # override create method, with no reload
  def self.create(opts)
    location = connection.post(self.resource_plural_name, self.resource_singular_name.to_sym => opts)
    newrecord = self.new('href' => location)
  end

end
