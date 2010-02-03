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

class Deployment < RightScale::Api::Base
  def self.resource_plural_name
    "deployments"
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

class Status < RightScale::Api::Base
  def wait_for_completed(audit_link = "no audit link available")
    while(1)
      reload
      return true if self.state == "completed"
      raise "FATAL error, script failed\nSee Audit: #{audit_link}" if self.state == 'failed'
      sleep 5
      connection.logger("querying status of right_script.. got: #{self.state}")
    end
  end
end

class Server < RightScale::Api::Base
  include SshHax

  def self.resource_plural_name
    "servers"
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
  
  def run_script(script)
    serv_href = URI.parse(self.href)
    location = connection.post(serv_href.path + '/run_script', :right_script => script.href)
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

  # special reload (overrides api_base), so that we can reload settings as well
  #def reload
  #  uri = URI.parse(self.href)
  #  @params = connection.get(uri.path)
  #  settings
  #end
end

class RightScript < RightScale::Api::Base
  def self.resource_plural_name
    "right_scripts"
  end

  def self.from_yaml(yaml)
    scripts = []
    x = YAML.load(yaml)
    x.keys.each do |script|
      scripts << self.new('href' => "right_scripts/#{script}", 'name' => x[script].ivars['name'])
    end
    scripts  
  end

  def self.from_instance_info(file = "/var/spool/ec2/rs_cache/info.yml")
    scripts = []
    if File.exists?(file)
      x = YAML.load(IO.read(file))
    elsif File.exists?(File.join(File.dirname(__FILE__),'info.yml'))
      x = YAML.load(IO.read(File.join(File.dirname(__FILE__),'info.yml')))
    else
      return nil
    end
    x.keys.each do |script|
      scripts << self.new('href' => "right_scripts/#{script}", 'name' => x[script].ivars['name'])
    end
    scripts  
  end

end
