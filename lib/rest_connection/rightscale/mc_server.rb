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
class McServer < Server
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend
  
  def resource_plural_name
    "servers"
  end

  def resource_singular_name
    "server"
  end

  def self.resource_plural_name
    "servers"
  end

  def self.resource_singular_name
    "server"
  end
  
  def self.create(opts)
    server = {}
    server[:name] = opts[:nickname] if opts[:nickname]
    server[:deployment_href] = opts[:deployment_href] if opts[:deployment_href]
    server[:instance] = {:server_template_href => opts[:server_template_href]}
    server[:instance][:cloud_href] = "https://my.rightscale.com/api/clouds/#{opts[:cloud_id]}"
    server[:instance][:multi_cloud_image_href] = opts[:mci_href]
    server[:instance][:instance_type_href] = nil #TODO.....
    server[:instance][:inputs] = opts[:inputs]
    location = connection.post(self.resource_plural_name, {self.resource_singular_name.to_sym => server})
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord
end
