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

class Server 
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include SshHax

  def self.create(opts)
    create_options = Hash.new
    create_options[self.resource_singular_name.to_sym] = opts
    create_options["cloud_id"] = opts[:cloud_id] if opts[:cloud_id]
    location = connection.post(self.resource_plural_name,create_options)    
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord
  end

  # waits until the specified state is reached for this Server
  # *st <~String> the name of the state to wait for, eg. "operational"
  # *timeout <~Integer> optional, how long to wait for the state before declare failure (in seconds).
  def wait_for_state(st,timeout=900)
    reload
    connection.logger("#{nickname} is #{self.state}")
    while(timeout > 0)
      return true if state == st
      raise "FATAL error, this server is stranded and needs to be #{st}: #{nickname}, see audit: #{self.audit_link}" if state.include?('stranded')
      sleep 5
      timeout -= 5
      connection.logger("waiting for server #{nickname} to go #{st}, state is #{state}")
      reload
    end
    raise "FATAL, this server #{self.audit_link} timed out waiting for the state to be #{st}" if timeout <= 0
  end

  # waits until the server is operational and dns_name is available
  def wait_for_operational_with_dns
    timeout = 300
    wait_for_state("operational")
    while(timeout > 0)
      self.settings
      break if self['dns-name'] && !self['dns-name'].empty?
      connection.logger "waiting for dns-name for #{self.nickname}"
      sleep 5
      timeout -= 5
    end
    connection.logger "got DNS: #{self['dns-name']}"
    raise "FATAL, this server #{self.audit_link} timed out waiting for DNS" if timeout <= 0
  end

  def audit_link
    # proof of concept for now
    server_id = self.href.split(/\//).last
    audit_href = "https://my.rightscale.com/servers/#{server_id}#audit_entries"
    "<a href='#{audit_href}'>#{audit_href}</a>"
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

# Uses ServerInternal api to start and stop EBS based instances
  def start_ebs
    @server_internal = ServerInternal.new(:href => self.href)
    @server_internal.start
  end

  def stop_ebs
    @server_internal = ServerInternal.new(:href => self.href)
    @server_internal.stop
  end

  # This should be used with v5 images only.
  # executable to run can be an Executable or RightScript object
  def run_executable(executable, opts=nil)
    script_options = Hash.new
    script_options[:server] = Hash.new
    if executable.is_a?(Executable)
      if executable.recipe?
        script_options[:server][:recipe] = executable.recipe
      else
        script_options[:server][:right_script_href] = executable.right_script.href
      end
    elsif executable.is_a?(RightScript)
      script_options[:server][:right_script_href] = executable.href
    else
      raise "Invalid class passed to run_executable, needs Executable or RightScript, was:#{executable.class}"
    end

    serv_href = URI.parse(self.href)
    script_options[:server][:parameters] = opts unless opts.nil?
    location = connection.post(serv_href.path + '/run_executable', script_options)
    AuditEntry.new('href' => location)
  end

  # This should be used with v4 images only.
  def run_script(script,opts=nil)
    if script.is_a?(Executable)
      script = script.right_script
    end
    serv_href = URI.parse(self.href)
    script_options = Hash.new
    script_options[:server] = Hash.new
    script_options[:server][:right_script_href] = script.href
    script_options[:server][:parameters] = opts unless opts.nil?
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

  # takes Bool argument to wait for state change (insurance that we can detect a reboot happened)
  def reboot(wait_for_state = false)
    reload
    old_state = self.state
    serv_href = URI.parse(self.href)
    connection.post(serv_href.path + "/reboot") 
    if wait_for_state
      wait_for_state_change(old_state)
    end
  end

  def events
    my_events = Event.new
    id = self.href.split(/\//).last
    my_events.filter_by(:server_id, id)
  end

  def relaunch
    self.stop
    self.wait_for_state("stopped")
    self.start  
  end

  def wait_for_state_change(old_state = nil)
    timeout = 60*7
    timer = 0
    while(timer < timeout)
      reload
      old_state = self.state unless old_state
      connection.logger("#{nickname} is #{self.state}")
      return true if self.state != old_state
      sleep 5
      timer += 5
      connection.logger("waiting for server #{nickname} to change from #{old_state} state.")
    end
    raise("FATAL: timeout after #{timeout}s waiting for state change")
  end

#  DOES NOT WORK: fragile web scraping
#  def relaunch
#    unless state == "stopped"
#      wind_monkey
#      server_id = self.href.split(/\//).last
#      base_url = URI.parse(self.href)
#      base_url.path = "/servers/#{server_id}"
#
#      s = agent.get(base_url.to_s)
#      relaunch = s.links.detect {|d| d.to_s == "Relaunch"}
#      prelaunch_page = agent.get(relaunch.href)
#      debugger
#      launch_form = prelaunch_page.forms[2]
#      launch_form.radiobuttons_with(:name => 'launch_immediately').first.check
#      agent.submit(launch_form, launch_form.buttons.first)
#    else
#      connection.logger("WARNING: detected server is #{self.state}, skipping relaunch")
#    end
#  end
end

