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

require 'rest_connection/mechanize_connection'
require 'ruby-debug'

class Event
  include MechanizeConnection::Connection

   def get_events_feed
      wind_monkey
      raise "FATAL: you must set settings[:events_feed_url] to a valid rightscale feed url+feed_token to use the events feed." unless connection.settings[:events_feed_url]
      url = connection.settings[:events_feed_url]  
      agent.get(url)
      debugger
      puts "wootywoot"
    end

end
