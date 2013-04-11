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
# API 0.1
#
class MultiCloudImageInternal
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Internal
  extend RightScale::Api::InternalExtend

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

  def commit(message)
    t = URI.parse(self.href)
    MultiCloudImage.new(:href => connection.post(t.path + "/commit"))
  end

  def clone
    t = URI.parse(self.href)
    MultiCloudImage.new(:href => connection.post(t.path + "/clone"))
  end

  def transform_settings
    if @params["multi_cloud_image_cloud_settings"] && @params["multi_cloud_image_cloud_settings"].first.is_a?(Hash)
      @params["multi_cloud_image_cloud_settings"].map! { |setting|
        # Have to reject because API0.1 returns all clouds
        next if setting["fingerprint"] || setting["cloud_id"] > 10
        MultiCloudImageCloudSettingInternal.new(setting)
      }
      @params["multi_cloud_image_cloud_settings"].compact!
    end
  end

  def initialize(params={})
    @params = params
    transform_settings
  end

  def settings
    transform_settings
    @params["multi_cloud_image_cloud_settings"]
  end

  def supported_cloud_ids
    @params["multi_cloud_image_cloud_settings"].map { |mcics| mcics.cloud_id }
  end
end
