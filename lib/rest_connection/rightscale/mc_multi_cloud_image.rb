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
# You must have Beta v1.5 API access to use these internal API calls.
#
class McMultiCloudImage
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend
  include RightScale::Api::McTaggable
  extend RightScale::Api::McTaggableExtend
  attr_reader :settings

  deny_methods :create, :destroy, :update

  def resource_plural_name
    "multi_cloud_images"
  end

  def resource_singular_name
    "multi_cloud_image"
  end

  def self.resource_plural_name
    "multi_cloud_images"
  end

  def self.resource_singular_name
    "multi_cloud_image"
  end

  def self.parse_args(server_template_id=nil)
    server_template_id ? "server_templates/#{server_template_id}/" : ""
  end

  def self.filters
    [:description, :name, :revision]
  end

  def supported_cloud_ids
    @settings.map { |mcics| mcics.cloud_id }
  end

  def get_settings
    @settings = []
    url = URI.parse(self.href)
    connection.get(url.path + '/settings').each { |s|
      @settings << McMultiCloudImageSetting.new(s)
    }
    @settings
  end
end
