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

class Tag
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  deny_methods :index, :create, :destroy, :update, :show

  def self.search(resource_name, tags, opts=nil)
    parameters = { :resource_type => resource_name.to_s, :tags => tags }
    parameters.merge!(opts) unless opts.nil?
    result = connection.get("tags/search", parameters)
  end

  def self.search_by_href(resource_href)
      connection.get("tags/search", :resource_href => resource_href)
  end
  #TAGGABLE_RESOURCES = [ 'Server', 'Ec2EbsSnapshot', 'Ec2EbsVolume', 'Ec2Image', 'Image', 'ServerArray', 'Ec2Instance',
  #                        'Instance', 'Deployment', 'ServerTemplate', 'Ec2ServerTemplate' ]
  #
  # Tag.set( resource_href, tags ) where tags is an array of tags to set on the resource.
  def self.set(resource_href, tags)
    connection.put("tags/set", :resource_href => resource_href, :tags => tags)
  end

  def self.unset(resource_href, tags)
    connection.put("tags/unset", :resource_href => resource_href, :tags => tags)
  end
end
