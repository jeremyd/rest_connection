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
class McDeployment
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend
  include RightScale::Api::McTaggable
  extend RightScale::Api::McTaggableExtend
  include RightScale::Api::McInput

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

  def self.filters
    [:description, :name]
  end

  def self.create(opts)
    location = connection.post(resource_plural_name, opts)
    newrecord = self.new('href' => location)
    newrecord.show
    newrecord
  end

  def save
    inst_href = URI.parse(self.href)
    connection.put(inst_href.path, @params)
  end

  # TODO Add server method

  def destroy
    deploy_href = URI.parse(self.href)
    connection.delete(deploy_href.path)
  end
end
