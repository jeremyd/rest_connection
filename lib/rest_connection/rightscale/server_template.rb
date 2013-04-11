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
class ServerTemplate
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Taggable
  extend RightScale::Api::TaggableExtend

  attr_accessor :internal

  def initialize(*args, &block)
    super(*args, &block)
    if RightScale::Api::api0_1?
      @internal = ServerTemplateInternal.new(*args, &block)
    end
  end

  def reload
    ret = connection.get(URI.parse(self.href).path, :include_mcis => true)
    @params ? @params.merge!(ret) : @params = ret
    @params["multi_cloud_images"].map! { |mci_params| MultiCloudImage.new(mci_params) }
    @params["default_multi_cloud_image"] = MultiCloudImage.new(@params["default_multi_cloud_image"])
    @params
  end

  def executables
    unless @params["executables"]
      fetch_executables
    end
    @params["executables"]
  end

  def alert_specs
    unless @params["alert_specs"]
      fetch_alert_specs
    end
    @params["alert_specs"]
  end

  def fetch_alert_specs
    my_href = URI.parse(self.href)
    as = []
    connection.get(my_href.path + "/alert_specs").each do |e|
      as << AlertSpec.new(e)
    end
    @params["alert_specs"] = as
  end

  def multi_cloud_images
    unless @params["multi_cloud_images"]
      fetch_multi_cloud_images
    end
    @params["multi_cloud_images"]
  end

  def fetch_executables
    my_href = URI.parse(self.href)
    ex = []
    connection.get(my_href.path + "/executables").each do |e|
      ex << Executable.new(e)
    end
    @params["executables"] = ex
  end

  def fetch_multi_cloud_images
    @params["multi_cloud_images"] = []
    ServerTemplateInternal.new(:href => self.href).multi_cloud_images.each { |mci_params|
      @params["multi_cloud_images"] << MultiCloudImageInternal.new(mci_params)
    }
    mcis = McServerTemplate.find(self.rs_id.to_i).multi_cloud_images
    @params["multi_cloud_images"].each_index { |i|
      @params["multi_cloud_images"][i]["multi_cloud_image_cloud_settings"] += mcis[i].settings
    }
    @params["multi_cloud_images"]
  end

  # The RightScale api calls this 'duplicate' but is more popularly known as 'clone' from a users perspective
  def duplicate
    my_href = URI.parse(self.href)
    ServerTemplate.new(:href => connection.post(my_href.path + "/duplicate"))
  end

  def clone
    duplicate
  end

end
