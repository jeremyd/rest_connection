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

class RightScriptAttachmentInternal
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Internal
  extend RightScale::Api::InternalExtend

  def resource_plural_name
    "right_script_attachments"
  end

  def resource_singular_name
    "right_script_attachment"
  end

  def self.resource_plural_name
    "right_script_attachments"
  end

  def self.resource_singular_name
    "right_script_attachment"
  end

  def self.get_s3_upload_params(right_script_href)
    url = self.resource_plural_name + "/get_s3_upload_params"
    connection.get(url, {"right_script_href" => right_script_href})
  end

=begin
  def self.upload(filedata, right_script_href) # TODO
  end

  def download # TODO
  end
=end
end
