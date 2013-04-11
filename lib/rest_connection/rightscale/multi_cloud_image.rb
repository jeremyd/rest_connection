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
class MultiCloudImage
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  deny_methods :create, :destroy, :update

  attr_accessor :internal

  def supported_cloud_ids
    @params["multi_cloud_image_cloud_settings"].map { |mcics| mcics.cloud_id }
  end

  # You must have access to multiple APIs for this (0.1, and 1.5)
  def find_and_flatten_settings()
    internal = MultiCloudImageInternal.new("href" => self.href)
    internal.reload
    total_image_count = internal.multi_cloud_image_cloud_settings.size
    # The .settings call filters out non-ec2 images
    more_settings = []
    if total_image_count > internal.settings.size
      more_settings = McMultiCloudImage.find(rs_id.to_i).settings
    end
    @params["multi_cloud_image_cloud_settings"] = internal.settings + more_settings
  end

  def initialize(*args, &block)
    super(*args, &block)
    if RightScale::Api::api0_1?
      @internal = MultiCloudImageInternal.new(*args, &block)
    end
  end

end
