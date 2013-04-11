#--
# Copyright (c) 2010-2012 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

#
# API 1.5
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
