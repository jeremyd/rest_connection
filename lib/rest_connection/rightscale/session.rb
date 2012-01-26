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

#
# You must have Beta v1.5 API access to use these internal API calls.
#
class Session
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :index, :destroy, :update, :show

  def self.index
    self.new(connection.get(resource_singular_name))
  end

  def self.create(opts={})
    settings = connection.settings
    ignored, account = settings[:api_url].split(/\/acct\//) if settings[:api_url].include?("acct")
    params = {
      "email" => settings[:user],
      "password" => settings[:pass],
      "account_href" => "/api/accounts/#{account}"
    }.merge(opts)
    resp = connection.post(resource_singular_name, params)
    connection.cookie = resp.response['set-cookie']
  end

  def self.accounts(opts={})
    settings = connection.settings
    params = {
      "email" => settings[:user],
      "password" => settings[:pass],
    }.merge(opts)
    a = Array.new
    connection.get(resource_singular_name + "/accounts").each do |object|
      a << Account.new(object)
    end
    return a
  end

  def self.create_instance_session
    # TODO
  end

  def self.index_instance_session
    # TODO
  end
end
