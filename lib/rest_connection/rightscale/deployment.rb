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

class Deployment
  class McDeployment
    include RightScale::Api::Gateway
    extend RightScale::Api::GatewayExtend
  
    def resource_plural_name
      "deployments"
    end 

    def resource_singular_name
      "deployment"
    end 

    def self.resource_plural_name
      "deployments"
    end 

    def self.resource_singular_name
      "deployment"
    end
  end

  class EC2Deployment
    include RightScale::Api::Base
    extend RightScale::Api::BaseExtend
  
    def resource_plural_name
      "deployments"
    end 

    def resource_singular_name
      "deployment"
    end 

    def self.resource_plural_name
      "deployments"
    end 

    def self.resource_singular_name
      "deployment"
    end
  end

  def initialize(params = {})
    if params[:cloud_id].to_i < 10
      @deploy = Deployment::EC2Deployment.new(params)
    else
      @deploy = Deployment::McDeployment.new(params)
    end
  end

  def method_missing(method_name, *args)
    @deploy.method_missing(method_name, *args)
  end

  def create(opts)
    location = connection.post(@deploy.resource_plural_name, @deploy.resource_singular_name.to_sym => opts)
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord
  end

  def set_input(name, value)
    deploy_href = URI.parse(@deploy.href)
    connection.put(deploy_href.path, :deployment => {:parameters => {name => value} })
  end

  def servers_no_reload
    server_list = []
    @params['servers'].each do |s|
      if s["server_type"] == "ec2"
        server_list << Server.new(s)
      else
        server_list << McServer.new(s)
      end
    end
    return server_list
  end

  def servers
    # this populates extra information about the servers
    servers_no_reload.each do |s|
      s.reload
    end
  end

  def duplicate
    clone
  end

  def clone
    deploy_href = URI.parse(@deploy.href)
    Deployment.new(:href => connection.post(deploy_href.path + "/duplicate"))
  end
end
