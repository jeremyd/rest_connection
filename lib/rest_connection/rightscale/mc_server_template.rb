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
class McServerTemplate
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend
  include RightScale::Api::McTaggable
  extend RightScale::Api::McTaggableExtend
  
  def resource_plural_name
    "server_templates"
  end

  def resource_singular_name
    "server_template"
  end

  def self.resource_plural_name
    "server_templates"
  end

  def self.resource_singular_name
    "server_template"
  end
  
  def get_mcis_and_settings
    @params["multi_cloud_images"] = McMultiCloudImage.find_all(self.rs_id)
    @params["multi_cloud_images"].each { |mci| mci.get_settings }
  end

  def multi_cloud_images
    unless @params["multi_cloud_images"]
      get_mcis_and_settings
    end
    @params["multi_cloud_images"]
  end
end
