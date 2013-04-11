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
class McTag
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :index, :show, :create, :destroy, :update

  def resource_plural_name
    "tags"
  end

  def resource_singular_name
    "tag"
  end

  def self.resource_plural_name
    "tags"
  end

  def self.resource_singular_name
    "tag"
  end

  def self.search(resource_name, tags, opts=nil) #, include_tags_with_prefix = false)
    parameters = { :resource_type => resource_name.to_s, :tags => tags }
    parameters.merge!(opts) unless opts.nil?
    result = connection.post("tags/by_tag", parameters)
  end

  def self.search_by_href(*resource_hrefs)
    connection.post("tags/by_resource", :resource_hrefs => resource_hrefs)
  end
  #TAGGABLE_RESOURCES = [ 'Server', 'Ec2EbsSnapshot', 'Ec2EbsVolume', 'Ec2Image', 'Image', 'ServerArray', 'Ec2Instance',
  #                        'Instance', 'Deployment', 'ServerTemplate', 'Ec2ServerTemplate' ]
  #
  # Tag.set( resource_href, tags ) where tags is an array of tags to set on the resource.
  def self.multi_add(resource_hrefs, tags)
    resource_hrefs = [resource_hrefs] unless resource_hrefs.is_a?(Array)
    connection.post("tags/multi_add", :resource_hrefs => resource_hrefs, :tags => tags)
  end

  def self.set(resource_hrefs, tags)
    self.multi_add(resource_hrefs, tags)
  end

  def self.multi_delete(resource_hrefs, tags)
    resource_hrefs = [resource_hrefs] unless resource_hrefs.is_a?(Array)
    connection.post("tags/multi_delete", :resource_hrefs => resource_hrefs, :tags => tags)
  end

  def self.unset(resource_hrefs, tags)
    self.multi_delete(resource_hrefs, tags)
  end
end
