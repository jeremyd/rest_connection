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

class Ec2SecurityGroup
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  # NOTE - Create, Destroy, and Update require "security_manager" permissions
  # NOTE - Can't remove rules, can only add
  def add_rule(opts={})
    opts.each { |k,v| opts["#{k}".to_sym] = v }
    update_types = [
      :name => [:owner, :group],
      :cidr_ips => [:cidr_ip, :protocol, :from_port, :to_port],
      :group => [:owner, :group, :protocol, :from_port, :to_port],
    ]
    type = (opts[:protocol] ? (opts[:cidr_ip] ? :cidr_ips : :group) : :name)
    unless update_types[type].reduce(true) { |b,field| b && opts[field] }
      arg_expectation = update_types.values.pretty_inspect
      raise ArgumentError.new("add_rule requires one of these groupings: #{arg_expectation}")
    end

    params = {}
    update_types[type].each { |field| params[field] = opts[field] }

    uri = URI.parse(self.href)
    connection.put(uri.path, params)

    self.reload
  end
end
