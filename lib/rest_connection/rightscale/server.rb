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
    create_options[self.resource_singular_name.to_sym][:mci_href] = nil
    create_options[self.resource_singular_name.to_sym][:inputs] = nil
    location = connection.post(self.resource_plural_name,create_options)    
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord
  end

  # The RightScale api returns the server parameters as a hash with "name" and "value".  
  # This must be transformed into a hash in case we want to PUT this back to the API.
  def transform_parameters(parameters)
    new_params_hash = {}
    parameters.each do |parameter_hash|
      new_params_hash[parameter_hash["name"]] = parameter_hash["value"]
    end
    new_params_hash
  end

  # Since RightScale hands back the parameters with a "name" and "value" tags we should
  # transform them into the proper hash.  This it the same for setting and getting.
  def parameters
    # if the parameters are an array of hashes, that means we need to transform.
    if @params['parameters'].is_a?(Array)
      @params['parameters'] = transform_parameters(@params['parameters'])
    end
    @params['parameters']
  end

  # This is overriding the default save with one that can massage the parameters
  def save
    uri = URI.parse(self.href)
    connection.put(uri.path, resource_singular_name.to_sym => @params)
  end

  # waits until the specified state is reached for this Server
  # *st <~String> the name of the state to wait for, eg. "operational"
  # *timeout <~Integer> optional, how long to wait for the state before declare failure (in seconds).
  def wait_for_state(st,timeout=1200)
    reload
    connection.logger("#{nickname} is #{self.state}")
    step = 15
    catch_early_terminated = 120 / step
    while(timeout > 0)
      return true if state =~ /#{st}/
      raise "FATAL error, this server is stranded and needs to be #{st}: #{nickname}, see audit: #{self.audit_link}" if state.include?('stranded') && !st.include?('stranded')
      connection.logger("waiting for server #{nickname} to go #{st}, state is #{state}")
      if state =~ /terminated|stopped/ and st !~ /terminated|stopped/
        if catch_early_terminated <= 0
          raise "FATAL error, this server terminated when waiting for #{st}: #{nickname}"
        end
        catch_early_terminated -= 1
      end
      sleep step
      timeout -= step
      reload
    end
    raise "FATAL, this server #{self.audit_link} timed out waiting for the state to be #{st}" if timeout <= 0
  end

  # waits until the server is operational and dns_name is available
  def wait_for_operational_with_dns(state_wait_timeout=1200)
    timeout = 600
    wait_for_state("operational", state_wait_timeout)
    step = 15
    while(timeout > 0)
      self.settings
      break if self['dns-name'] && !self['dns-name'].empty? && self['private-dns-name'] && !self['private-dns-name'].empty? 
      connection.logger "waiting for dns-name for #{self.nickname}"
      sleep step
      timeout -= step
    end
    connection.logger "got DNS: #{self['dns-name']}"
    raise "FATAL, this server #{self.audit_link} timed out waiting for DNS" if timeout <= 0
  end

  def audit_link
    # proof of concept for now
    server_id = self.href.split(/\//).last
    audit_href = "https://my.rightscale.com/servers/#{server_id}#auditentries"
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
    # All instances will have a valid href including EBS instances that are "stopped"
    if self.current_instance_href
      t = URI.parse(self.href)
      connection.post(t.path + '/stop')
    else
      connection.logger("WARNING: was in #{self.state} and had a current_instance_href so skiping stop call")
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

  # Works on v4 and v5 images.
  # *executable can be an <~Executable> or <~RightScript>
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

  def set_inputs(hash = {})
    serv_href = URI.parse(self.href)
    connection.put(serv_href.path, :server => {:parameters => hash})
  end

  def set_template(href)
    serv_href = URI.parse(self.href)
    connection.put(serv_href.path, :server => {:server_template_href => href})
  end

  def settings
    serv_href = URI.parse(self.href)
    @params.merge! connection.get(serv_href.path + "/settings")
  end

  def attach_volume(params)
    hash = {}
    hash[:server] = params 
    serv_href = URI.parse(self.href)
    connection.post(serv_href.path + "/attach_volume", hash)
  end

  def get_sketchy_data(params = {})
    serv_href = URI.parse(self.href)
    @params.merge! connection.get(serv_href.path + "/get_sketchy_data", params)
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
      sleep 30
      timer += 30
      connection.logger("waiting for server #{nickname} to change from #{old_state} state.")
    end
    raise("FATAL: timeout after #{timeout}s waiting for state change")
  end

  # Save the servers parameters to the current server (instead of the next server)
  def save_current
    uri = URI.parse(self.href)
    connection.put(uri.path + "/current", resource_singular_name.to_sym => @params)
  end

  # Load server's settings from the current server (instead of the next server)
  def settings_current
    serv_href = URI.parse(self.href)
    @params.merge! connection.get(serv_href.path + "/current" + "/settings")
  end

  # Reload the server's basic information from the current server.
  def reload_current
    uri = URI.parse(self.href)
    @params ? @params.merge!(connection.get(uri.path + "/current")) : @params = connection.get(uri.path)
  end

end

