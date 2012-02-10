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

class Ec2ServerArray
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Taggable
  extend RightScale::Api::TaggableExtend

  deny_methods :index, :show, :create, :update, :destroy

  def run_script_on_instances(script, ec2_instance_hrefs=[], opts={})
    uri = URI.parse(self.href)
    case script
    when Executable then script = script.right_script
    when String then script = RightScript.new('href' => script)
    end

    params = {:right_script_href => script.href}
    unless ec2_instance_hrefs.nil? || ec2_instance_hrefs.empty?
      params[:ec2_instance_hrefs] = ec2_instance_hrefs
    end
    unless opts.nil? || opts.empty?
      params[:parameters] = opts
    end
    params = {:ec2_server_array => params}
    connection.post(uri.path + "/run_script_on_instances", params).map do |work_unit|
      Status.new('href' => location)
    end
  end
end
