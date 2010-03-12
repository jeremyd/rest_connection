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

class Event < RightScale::Api::Base
  include MechanizeConnection::Connection
  
  attr_accessor :cache

  def initialize
    get_events    
    self
  end

  def filter_by(search, tag)
    if search == :server_id
      view = @cache.select do |k,v| 
        v =~ /servers%2F#{tag}\"/
      end
    elsif search == :acct_id
# TODO: regex for acct id
    elsif search == :server_nickname
      # the server nickname (subject) is in the key of the events hash
      view = events.select { |e| e.keys.include?(tag) }
    end
    view
  end

  def get_events
    raise "FATAL: you must set settings[:events_feed_url] to a valid rightscale feed url+feed_token to use the events feed." unless connection.settings[:events_feed_url]
    url = connection.settings[:events_feed_url]  
    feed = agent.get(url)
    doc = Nokogiri::XML(feed.body)
    entries = doc.search("entry")
    events = {}
    entries.each do |e|
      events[e.search("title").children.text] = e.search("content").text
      #events[e.search("title").children.text] = e.search("link").to_s
    end

    # might work for json?
    #feed = agent.get("https://my.rightscale.com/user_notifications/update_events", {"X-Requested-With" => "XMLHttpRequest"})
    
    @cache = events
  end

end
