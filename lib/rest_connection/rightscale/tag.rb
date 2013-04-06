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
# API 1.0
#
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
