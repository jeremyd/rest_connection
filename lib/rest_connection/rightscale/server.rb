#--
# Copyright (c) 2010-2012 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

#
# API 1.0
#
class Server
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include SshHax
  include RightScale::Api::Taggable
  extend RightScale::Api::TaggableExtend

  attr_accessor :internal

  def self.filters
    [
      :aws_id,
      :created_at,
      :deployment_href,
      :ip_address,
      :nickname,
      :private_ip_address,
      :updated_at
    ]
  end

  def self.create(opts)
    create_options = Hash.new
    create_options[self.resource_singular_name.to_sym] = opts
    create_options["cloud_id"] = opts[:cloud_id] if opts[:cloud_id]
    create_options[self.resource_singular_name.to_sym][:mci_href] = nil
    create_options[self.resource_singular_name.to_sym][:inputs] = nil
    location = connection.post(self.resource_plural_name,create_options)
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord.parameters #transform the parameters!
    newrecord
  end

  def initialize(*args, &block)
    super(*args, &block)
    if RightScale::Api::api0_1?
      @internal = ServerInternal.new(*args, &block)
    end
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
    @params['parameters'] ||= {}
  end

  # This is overriding the default save with one that can massage the parameters
  def save
    self.parameters #transform the parameters, if they're not already!!
    self.tags #transform the tags, if they're not already!!
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
    catch_early_terminated = 1200 / step
    while(timeout > 0)
      return true if state =~ /#{st}/
      return true if state =~ /terminated|stopped/ && st =~ /terminated|stopped/
      raise "FATAL error, this server is stranded and needs to be #{st}: #{nickname}, see audit: #{self.audit_link}" if state.include?('stranded') && !st.include?('stranded')
      raise "FATAL error, this server went to error state and needs to be #{st}: #{nickname}, see audit: #{self.audit_link}" if state.include?('error') && st !~ /error|terminated|stopped/
      connection.logger("waiting for server #{nickname} to go #{st}, state is #{state}")
      if state =~ /terminated|stopped|inactive|error/ and st !~ /terminated|stopped|inactive|error/
        if catch_early_terminated <= 0
          raise "FATAL error, this server entered #{state} state waiting for #{st}: #{nickname}"
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
  def wait_for_operational_with_dns(operational_timeout_in_seconds = 1200, dns_timeout_in_seconds = operational_timeout_in_seconds / 2)
    # First, wait for the server to go operational
    wait_for_state("operational", operational_timeout_in_seconds)

    # Log that we are switching to waiting for dns
    connection.logger "#{self.nickname} is operational, now checking for dns name/ip address..."

    # Now poll for valid dns
    dns_timeout = dns_timeout_in_seconds
    dns_step = 15
    while(dns_timeout > 0)
      self.settings
      if self.reachable_ip
        # Got a dns name/ip address so log that and return (note that "reachable_ip" returns a dns name on AWS and an ip address on generic clouds)
        connection.logger "Got dns name/ip address: #{self.reachable_ip}."
        return
      end
      connection.logger "Waiting #{dns_step} seconds before checking for dns name/ip address on #{self.nickname}..."
      sleep dns_step
      dns_timeout -= dns_step
    end

    raise "FATAL, server #{self.nickname}, #{self.audit_link} timed out waiting for dns name/ip address, waited for #{dns_timeout_in_seconds}."
  end

  def audit_link
    # proof of concept for now
#    server_id = self.href.split(/\//).last
#    audit_href = "https://my.rightscale.com/servers/#{server_id}#auditentries"
    audit_href = self.href.gsub(/api\//,"") + "#auditentries"
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

  def force_stop
    if self.current_instance_href
      t = URI.parse(self.href)
      connection.post(t.path + '/stop')
      connection.post(t.path + '/stop')
    else
      connection.logger("WARNING: was in #{self.state} and had a current_instance_href so skiping stop call")
    end
  end

# Uses ServerInternal api to start and stop EBS based instances
  def start_ebs
#    @server_internal = ServerInternal.new(:href => self.href)
#    @server_internal.start
    if self.state == "stopped"
      t = URI.parse(self.href)
      return connection.post(t.path + '/start_ebs')
    else
      connection.logger("WARNING: was in #{self.state} so skiping start_ebs call")
    end
  end

  def stop_ebs
#    @server_internal = ServerInternal.new(:href => self.href)
#    @server_internal.stop
    if self.current_instance_href
      t = URI.parse(self.href)
      connection.post(t.path + '/stop_ebs')
    else
      connection.logger("WARNING: was in #{self.state} and had a current_instance_href so skiping stop_ebs call")
    end
  end

  # Works on v4 and v5 images.
  # *executable can be an <~Executable> or <~RightScript>
  def run_executable(executable, opts=nil, ignore_lock=false)
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

    if not opts.nil? and opts.has_key?(:ignore_lock)
      script_options[:server][:ignore_lock] = "true"
      opts.delete(:ignore_lock)
    end

    serv_href = URI.parse(self.href)
    script_options[:server][:parameters] = opts unless opts.nil?
    script_options[:server][:ignore_lock] = "true" if ignore_lock
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
    set_current_inputs(hash)
    set_next_inputs(hash)
  end

  def set_current_inputs(hash = {})
    if self.current_instance_href and self.state != "stopped"
      self.reload_as_current
      serv_href = URI.parse(self.href)
      connection.put(serv_href.path, :server => {:parameters => hash})
      settings
      self.reload_as_next
    end
  end

  def set_next_inputs(hash = {})
    serv_href = URI.parse(self.href)
    connection.put(serv_href.path, :server => {:parameters => hash})
    settings
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
  # *timeout <~Integer> optional, how long to wait for the stopped state before declare failure (in seconds).
  def reboot(wait_for_state = false, timeout = 60*7)
    reload
    old_state = self.state
    serv_href = URI.parse(self.href)
    connection.post(serv_href.path + "/reboot")
    if wait_for_state
      wait_for_state_change(old_state, timeout)
    end
  end

  def alert_specs
    # TODO
  end

  # *timeout <~Integer> optional, how long to wait for the stopped state before declare failure (in seconds).
  def relaunch(timeout=1200)
    self.stop
    self.wait_for_state("stopped", timeout)
    self.start
  end

  # *timeout <~Integer> optional, how long to wait for the stopped state before declare failure (in seconds).
  def wait_for_state_change(old_state = nil, timeout = 60*7)
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

  # Reload the server's basic information from the current server instance
  def reload_as_current
    uri = URI.parse(self.href + "/current")
    @params.merge! connection.get(uri.path)
  end

  # Reload the server's basic information from the next server instance
  def reload_as_next
    uri = URI.parse(self.href.gsub(/\/current/,""))
    @params.merge! connection.get(uri.path)
  end

  # Complex logic for determining the cloud_id of even a stopped server
  def cloud_id
    self.settings
    if self.state == "operational"
      return self["cloud_id"]
    end
    cloud_ids = RightScale::Api::AWS_CLOUDS.map { |hsh| hsh["cloud_id"] }

    # Try ssh keys
    if self.ec2_ssh_key_href and RightScale::Api::api0_1?
      ref = self.ec2_ssh_key_href
      cloud_ids.each { |cloud|
        if Ec2SshKeyInternal.find_by_cloud_id(cloud.to_s).select { |o| o.href == ref }.first
          return cloud
        end
      }
    end

    # Try security groups
    if self.ec2_security_groups_href
      self.ec2_security_groups_href.each { |sg|
        cloud_ids.each { |cloud|
          if Ec2SecurityGroup.find_by_cloud_id(cloud.to_s).select { |o| o.href == sg }.first
            return cloud
          end
        }
      }
    end

    raise "Could not determine cloud_id...try setting an ssh key or security group"
  end

  def run_executable_and_wait_for_completed(executable, opts=nil)
    run_executable(executable, opts).wait_for_completed
  end

  def dns_name
    self.settings unless self["dns_name"]
    if self.current_instance_href
      self["dns_name"] ||= get_tags_by_namespace("server")["current_instance"]["public_ip_0"]
    end
    self["dns_name"]
  end

  def private_ip
    self.settings unless @params["private-ip-address"]
    if self.current_instance_href
      self["private-ip-address"] ||= get_tags_by_namespace("server")["current_instance"]["private_ip_0"]
    end
    @params["private-ip-address"]
  end

  def reachable_ip
    if ret = self.dns_name
      return ret
    elsif ret = self.private_ip
      return ret
    end
    nil
  end

  # Override Taggable mixin so that it sets tags on both next and current instances
  def tags(*args)
    self.reload_as_next if self.href =~ /current/
    super(*args)
  end

  def current_tags(reload=true)
    self.reload_as_next if self.href =~ /current/
    ret = []
    if self.current_instance_href
      ret = Tag.search_by_href(self.current_instance_href).map { |h| h["name"] }
    end
    ret
  end

  def add_tags(*args)
    self.reload_as_next if self.href =~ /current/
    return false if args.empty?
    args.uniq!
    Tag.set(self.href, args)
    Tag.set(self.current_instance_href, args) if self.current_instance_href
    self.tags(true)
  end

  def remove_tags(*args)
    self.reload_as_next if self.href =~ /current/
    return false if args.empty?
    args.uniq!
    Tag.unset(self.href, args)
    Tag.unset(self.current_instance_href, args) if self.current_instance_href
    self.tags(true)
  end

  def get_tags_by_namespace(namespace)
    ret = {}
    tags = {"self" => self.tags(true)}
    tags["current_instance"] = self.current_tags if self.current_instance_href
    tags.each { |res,ary|
      ret[res] ||= {}
      ary.each { |tag|
        next unless tag.start_with?("#{namespace}:")
        key = tag.split("=").first.split(":")[1..-1].join(":")
        value = tag.split(":")[1..-1].join(":").split("=")[1..-1].join("=")
        ret[res][key] = value
      }
    }
    return ret
  end

  def clear_tags(namespace = nil)
    tags = self.tags(true)
    tags.deep_merge! self.current_tags if self.current_instance_href
    tags = tags.select { |tag| tag.start_with?("#{namespace}:") } if namespace
    self.remove_tags(*tags)
  end

  def lock
    unless self.settings['locked']
      serv_href = URI.parse(self.href)
      res = connection.put(serv_href.path, :server => {:lock => 'true'})
      res.is_a?(Net::HTTPSuccess) ? true : false
    else
      connection.logger("Server is already locked")
    end
  end

  def unlock
    if self.settings['locked']
      serv_href = URI.parse(self.href)
      res = connection.put(serv_href.path, :server => {:lock => 'false'})
      res.is_a?(Net::HTTPSuccess) ? true : false
    else
      connection.logger("Server is already unlocked")
    end
  end

end
