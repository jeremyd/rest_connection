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

# Example:
# a = Ec2ServerArray.new(:href => "https://validhref")
# st = ServerTemplate.new(:href => "https://validhref")
# st.executables.find(:nickname
# a.run_script_on_all(

class Ec2ServerArray 
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  def run_script_on_all(script, server_template_hrefs, inputs=nil)
     serv_href = URI.parse(self.href)
     options = Hash.new
     options[:ec2_server_array] = Hash.new 
     options[:ec2_server_array][:right_script_href] = script.href
     options[:ec2_server_array][:parameters] = inputs unless inputs.nil?
     options[:ec2_server_array][:server_template_hrefs] = server_template_hrefs
     connection.post("#{serv_href.path}/run_script_on_all", options)
  end

  def instances
    serv_href = URI.parse(self.href)
    connection.get("#{serv_href.path}/instances")
  end 
  
  def terminate_all
    serv_href = URI.parse(self.href)
    connection.post("#{serv_href.path}/terminate_all")
  end
end

