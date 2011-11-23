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
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Taggable
  extend RightScale::Api::TaggableExtend

  def self.filters
    [:description, :nickname]
  end

  def reload
    uri = URI.parse(self.href)
    @params ? @params.merge!(connection.get(uri.path)) : @params = connection.get(uri.path)
    @params['cloud_id'] = cloud_id
    @params
  end

  def self.create(opts)
    location = connection.post(self.resource_plural_name, self.resource_singular_name.to_sym => opts)
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord
  end

  def set_inputs(hash = {})
    deploy_href = URI.parse(self.href)
    connection.put(deploy_href.path, :deployment => {:parameters => hash })
  end

  def set_input(name, value)
    deploy_href = URI.parse(self.href)
    connection.put(deploy_href.path, :deployment => {:parameters => {name => value} })
  end

  def servers_no_reload
    connection.logger("WARNING: No Servers in the Deployment!") if @params['servers'].empty?
    unless @params['servers'].reduce(true) { |bool,s| bool && s.is_a?(ServerInterface) }
      @params['servers'].map! { |s| ServerInterface.new(self.cloud_id, s, self.rs_id) }
    end
    @params['servers']
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
    deploy_href = URI.parse(self.href)
    Deployment.new(:href => connection.post(deploy_href.path + "/duplicate"))
  end

  def destroy(wait_for_servers = nil)
    deploy_href = URI.parse(self.href)
    if wait_for_servers
      servers_no_reload.each { |s| s.wait_for_state("stopped") }
    end
    connection.delete(deploy_href.path)
  end

  def start_all
    deploy_href = URI.parse(self.href)
    connection.post(deploy_href.path + "/start_all")
  end

  def stop_all
    deploy_href = URI.parse(self.href)
    connection.post(deploy_href.path + "/stop_all")
  end
end
