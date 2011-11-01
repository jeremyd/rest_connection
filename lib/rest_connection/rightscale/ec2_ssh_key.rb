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

class Ec2SshKey
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  def self.create(opts)
    create_opts = { self.resource_singular_name.to_sym => opts }
    create_opts['cloud_id'] = opts['cloud_id'] if opts['cloud_id']
    location = connection.post(self.resource_plural_name, create_opts)
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord
  end
end
