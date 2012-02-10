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
