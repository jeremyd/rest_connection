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

require 'mechanize'
require 'logger'
require 'uri'

module MechanizeConnection
  module Connection

    # creates/returns global mechanize agent
    def agent
      @@agent ||= WWW::Mechanize.new do |a|
        a.log = Logger.new(STDOUT)
        a.log.level = Logger::INFO
      end
    end

    # creates/returns global mechanize agent
    def self.agent
      @@agent ||= WWW::Mechanize.new do |a|
        a.log = Logger.new(STDOUT)
        a.log.level = Logger::INFO
      end
    end

    # login to rightscale dashboard /sessions/new using rest connection user and pass
    def wind_monkey
      base_url = URI.parse(connection.settings[:api_url])
      base_url.path = "/"
      if agent.cookie_jar.empty?(base_url)
        agent.user_agent_alias = 'Mac Safari'
        # Login
        base_url = URI.parse(connection.settings[:api_url])
        agent.user_agent_alias = 'Mac Safari'
        # Login
        base_url.path = "/sessions/new"
        login_page = agent.get(base_url)
        login_form = login_page.forms.first
        login_form.email = connection.settings[:user]
        login_form.password = connection.settings[:pass]
        agent.submit(login_form, login_form.buttons.first)
      end
    end
  end
end
