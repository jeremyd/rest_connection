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
# You must have special API access to use these internal API calls.
#
class RsInternal
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  def connection
    @@little_brother_connection ||= RestConnection::Connection.new
    settings = @@little_brother_connection.settings
    settings[:common_headers]["X_API_VERSION"] = "0.1"
    settings[:api_href] = settings[:api_url]
    settings[:extension] = ".js"
    @@little_brother_connection
  end

  def self.connection
    @@little_brother_connection ||= RestConnection::Connection.new
    settings = @@little_brother_connection.settings
    settings[:common_headers]["X_API_VERSION"] = "0.1"
    settings[:api_href] = settings[:api_url]
    settings[:extension] = ".js"
    @@little_brother_connection
  end

  def self.get_server_template_multi_cloud_images(server_template_href)
    connection.get("rs_internal/get_server_template_multi_cloud_images","server_template_href=#{server_template_href}")
  end

  def self.set_server_multi_cloud_image(server_href, mci_href)
    connection.put("rs_internal/set_server_multi_cloud_image", {:server_href => server_href, :multi_cloud_image_href => mci_href})
  end
end
