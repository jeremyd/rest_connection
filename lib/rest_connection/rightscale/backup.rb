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
class Backup
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :index

  def self.filters
    [:cloud_href, :committed, :completed, :from_master, :latest_before]
  end

  def self.find_all(lineage)
    index(lineage)
  end

  def self.find_with_filter(lineage, filter={})
    index(lineage, filter)
  end

  def self.index(lineage, filter={})
    filter_params = []
    filter.each { |key,val|
      unless self.filters.include?(key.to_sym)
        raise ArgumentError.new("#{key} is not a valid filter for resource #{self.resource_singular_name}")
      end
      filter_params << "#{key}==#{val}"
    }

    a = Array.new
    url = self.resource_plural_name
    hsh = {'lineage' => lineage}
    hsh.merge(:filter => filter_params) unless filter_params.empty?
    connection.get(url, hsh).each do |object|
      a << self.new(object)
    end

    return a
  end

  def self.cleanup(lineage, keep_last, params={})
    params.merge!('keep_last' => keep_last, 'lineage' => lineage)
    connection.post(resource_plural_name + "/cleanup", params)
  end

  def restore(instance_href, name=nil, description=nil)
    uri = URI.parse(self.href)
    params = {'instance_href' => instance_href}
    params.deep_merge!({'backup' => {'name' => name}}) if name
    params.deep_merge!({'backup' => {'description' => description}}) if description
    location = connection.post(uri.path + "/restore", params)
    Task.new('href' => location)
  end
end
