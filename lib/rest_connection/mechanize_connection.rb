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
        base_url.path = "/sessions/new"
        pushbtn = nil 
        agent.get(base_url) do |login_page|
          login_page.forms.first.email = connection.settings[:user]
          login_page.forms.first.password = connection.settings[:pass]
          pushbtn = login_page.forms.first.buttons.first
        end.submit(login_form, pushbtn)
      end
    end
  end
end
