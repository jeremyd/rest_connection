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

require 'rest_connection/ssh_hax'

class Server < RightScale::Api::Base
  include SshHax
  def self.create(opts)
    create_options = Hash.new
    create_options[self.resource_singluar_name.to_sym] = opts
    create_options["cloud_id"] = opts[:cloud_id] if opts[:cloud_id]
    location = connection.post(self.resource_plural_name,create_options)    
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord
  end

  def wait_for_state(st)
    reload
    connection.logger("#{nickname} is #{self.state}")
    while(1)
      return true if state == st
      raise "FATAL error, this server is stranded and needs to be #{st}: #{nickname}, see audit: #{self.audit_link}" if state.include?('stranded')
      sleep 5
      connection.logger("waiting for server #{nickname} to go #{st}, state is #{state}")
      reload
    end
  end

  def wait_for_operational_with_dns
    wait_for_state("operational")
    while(1)
      connection.logger "waiting for dns-name for #{self.nickname}"
      break if self['dns-name'] && !self['dns-name'].empty?
      self.settings
      sleep 2
    end
    connection.logger "got DNS: #{self['dns-name']}"
  end

  def audit_link
    # proof of concept for now
    server_id = self.href.split(/\//).last
    "https://my.rightscale.com/servers/#{server_id}#audit_entries"
  end

  def start
    if self.state == "stopped"
      t = URI.parse(self.href)
      return connection.post(t.path + '/start')
    else
      connection.logger("WARNING: was in #{self.state} so skiping start call")
    end
  end

  def stop
    if self.state != "stopped"
      t = URI.parse(self.href)
      connection.post(t.path + '/stop')
    else
      connection.logger("WARNING: was in #{self.state} so skiping stop call")
    end
  end

  # This method takes a RightScript or Executable, and optional run time parameters in an options hash.
  def run_script(script,opts=nil)
    serv_href = URI.parse(self.href)
    script_options = Hash.new
    script_options[:right_script] = script.href
    script_options[:server] = {:parameters => opts} unless opts.nil?
    location = connection.post(serv_href.path + '/run_script', script_options)
    Status.new('href' => location)
  end 

  def set_input(name, value)
    serv_href = URI.parse(self.href)
    connection.put(serv_href.path, :server => {:parameters => {name.to_sym => value} })
  end

  def set_template(href)
    serv_href = URI.parse(self.href)
    connection.put(serv_href.path, :server => {:server_template_href => href})
  end

  def settings
    serv_href = URI.parse(self.href)
    @params.merge! connection.get(serv_href.path + "/settings")
  end

  def get_sketchy_data
    serv_href = URI.parse(self.href)
    @params.merge! connection.get(serv_href.path + "/get_sketchy_data")
  end

  def monitoring
    serv_href = URI.parse(self.href)
    @params.merge! connection.get(serv_href.path + "/monitoring")
  end

  def reboot
    serv_href = URI.parse(self.href)
    connection.post(serv_href.path + "/reboot") 
  end

  def relaunch
    unless state == "stopped"
      wind_monkey
      server_id = self.href.split(/\//).last
      base_url = URI.parse(self.href)
      base_url.path = "/servers/#{server_id}"

      s = agent.get(base_url.to_s)
      relaunch = s.links.detect {|d| d.to_s == "Relaunch"}
      prelaunch_page = agent.get(relaunch.href)
      launch_form = prelaunch_page.forms[2]
      launch_form.radiobuttons_with(:name => 'launch_immediately').first.check
      agent.submit(launch_form, launch_form.buttons.first)
    else
      connection.logger("WARNING: detected server is #{self.state}, skipping relaunch")
    end
  end
end

