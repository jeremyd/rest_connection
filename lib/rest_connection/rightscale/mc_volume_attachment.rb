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
class McVolumeAttachment
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  def resource_plural_name
    "volume_attachments"
  end

  def resource_singular_name
    "volume_attachment"
  end

  def self.resource_plural_name
    "volume_attachments"
  end

  def self.resource_singular_name
    "volume_attachment"
  end

  def self.parse_args(cloud_id, instance_id=nil)
    return "clouds/#{cloud_id}/" unless instance_id
    return "clouds/#{cloud_id}/volumes/#{instance_id}/" if instance_id
  end

  def show
    inst_href = URI.parse(self.href)
    @params.merge! connection.get(inst_href.path)
  end
end
