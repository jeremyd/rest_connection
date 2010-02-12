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

class Deployment < RightScale::Api::Base
  def set_input(name, value)
    deploy_href = URI.parse(self.href)
    connection.put(deploy_href.path, :deployment => {:parameters => {name => value} })
  end

  def servers_no_reload
    server_list = []
    @params['servers'].each do |s|
      server_list << Server.new(s)
    end
    return server_list
  end

  def servers
    # this populates extra information about the servers
    servers_no_reload.each do |s|
      s.reload
    end
  end
end
