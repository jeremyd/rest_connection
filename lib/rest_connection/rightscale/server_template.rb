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
  def initialize(params)
    @params = params
    fetch_executables
  end
  
  def fetch_executables
    my_href = URI.parse(self.href)
    #@params.merge! :executables =? connection.get(my_href.path + "/executables")
    ex = []
    connection.get(my_href.path + "/executables").each do |e|
      ex << Executable.new(e)
    end
    @params["executables"] = ex
  end

  def fetch_multi_cloud_images
    @params["multi_cloud_images"] = RsInternal.get_server_template_multi_cloud_images(self.href)
  end
    
end
