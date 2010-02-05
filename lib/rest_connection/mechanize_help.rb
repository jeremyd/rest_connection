require 'mechanize'
require 'logger'
require 'uri'

module MechanizeHelper
  class Connection
    def agent
      @@agent = WWW::Mechanize.new do |a|
        a.log = Logger.new(STDOUT)
      end if @@agent == nil
    end

    def self.agent
      @@agent = WWW::Mechanize.new do |a|
        a.log = Logger.new(STDOUT)
      end if @@agent == nil
    end

    def wind_monkey
      base_url = URI.parse(connection.settings['api_url'])
      if agent.cookie_jar.empty?(base_url)
        agent.user_agent_alias = 'Mac Safari'
        # Login
        base_url = URI.parse(@@connection.settings['api_url'])
        base_url.path = "/sessions/new"
        
        login_page = agent.get("https://my.rightscale.com/sessions/new")
        login_form = login_page.forms.first
        login_form.email = connection.settings[:user]
        login_form.password = connection.settings[:password]
        agent.submit(login_form) #, login_form.buttons.first)
      end
    end
  end
end
