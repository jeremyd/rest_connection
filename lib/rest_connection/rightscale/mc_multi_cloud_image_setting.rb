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
class McMultiCloudImageSetting
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :update #supported in API, not imp'd in code yet

  def resource_plural_name
    "settings"
  end

  def resource_singular_name
    "setting"
  end

  def self.resource_plural_name
    "settings"
  end

  def self.resource_singular_name
    "setting"
  end

  def self.parse_args(multi_cloud_image_id)
    "multi_cloud_images/#{multi_cloud_image_id}/"
  end

  def self.filters
    [:cloud_href, :multi_cloud_image_href]
  end

  def cloud_id
    self.cloud.split(/\//).last.to_i
  end

  # API 1.5 MultiCloudImageSetting is posted to url
  # /api/multi_cloud_images/:id/settings but the object it posts to the
  # API is named :multi_cloud_image_setting => { attrs }
  def self.resource_post_name
    "multi_cloud_image_setting"
  end
end
