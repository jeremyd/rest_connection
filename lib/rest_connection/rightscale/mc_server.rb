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

#
# You must have Beta v1.5 API access to use these internal API calls.
#
class McServer < Server
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend
  include RightScale::Api::McTaggable
  extend RightScale::Api::McTaggableExtend
  attr_accessor :current_instance, :next_instance, :inputs

  def resource_plural_name
    "servers"
  end

  def resource_singular_name
    "server"
  end

  def self.resource_plural_name
    "servers"
  end

  def self.resource_singular_name
    "server"
  end

  def self.parse_args(deployment_id=nil)
    deployment_id ? "deployments/#{deployment_id}/" : ""
  end

  def self.filters
    [:deployment_href, :name]
  end

  def launch
    if actions.include?("launch")
      t = URI.parse(self.href)
      connection.post(t.path + '/launch')
    elsif self.state == "inactive"
      raise "FATAL: Server is in an unlaunchable state!"
    else
      connection.logger("WARNING: was in #{self.state} so skipping launch call")
    end
  end

  def terminate
    if actions.include?("terminate")
      t = URI.parse(self.href)
      connection.post(t.path + '/terminate')
      @current_instance = nil
#    elsif self.state != "inactive"
#      raise "FATAL: Server is in an interminable state!"
    else
      connection.logger("WARNING: was in #{self.state} so skipping terminate call")
    end
  end

  def force_terminate
    t = URI.parse(self.href)
    connection.post(t.path + '/terminate')
    connection.post(t.path + '/terminate')
    @current_instance = nil
  end

  def start #start_ebs
    raise "You shouldn't be here."
  end

  def stop #stop_ebs
    raise "You shouldn't be here."
  end

  def run_executable(executable, opts=nil)
    raise "Instance isn't running; Can't run executable" unless @current_instance
    @current_instance.run_executable(executable, opts)
  end

  def transform_inputs(sym, parameters)
    ret = nil
    if parameters.is_a?(Array) and sym == :to_h
      ret = {}
      parameters.each { |hash| ret[hash['name']] = hash['value'] }
    elsif parameters.is_a?(Hash) and sym == :to_a
      ret = []
      parameters.each { |key,val| ret << {'name' => key, 'value' => val} }
    end
    ret
  end

  def inputs
    if @current_instance
      @current_instance.show
      return transform_inputs(:to_h, @current_instance.inputs)
    else
      @next_instance.show
      return transform_inputs(:to_h, @next_instance.inputs)
    end
  end

  def set_input(name, value)
    settings unless @next_instance
    @current_instance.multi_update([{'name' => name, 'value' => value}]) if @current_instance
    @next_instance.multi_update([{'name' => name, 'value' => value}])
  end

  def set_current_inputs(hash = {})
    settings unless @next_instance
    @current_instance.multi_update(transform_inputs(:to_a, hash)) if @current_instance
  end

  def set_next_inputs(hash = {})
    settings unless @next_instance
    @next_instance.multi_update(transform_inputs(:to_a, hash))
  end


  def settings #show
    serv_href = URI.parse(self.href)
    @params = connection.get(serv_href.path, 'view' => 'instance_detail')
    if self['current_instance']
      @current_instance = McInstance.new(self['current_instance'])
      @current_instance.show
    end
    @next_instance = McInstance.new(self['next_instance'])
    @next_instance.show
    @params
  end

  def monitoring
    ret = @current_instance.fetch_monitoring_metrics
    raise "FATAL: Monitoring not available!" if ret.empty?
    ret
  end

  def relaunch
    self.terminate
    self.wait_for_state("inactive")
    self.launch
  end

  # Attributes taken for granted in API 1.0
  def server_type
    "gateway"
  end

  def server_template_href
    if @current_instance
      return @current_instance.server_template
    end
    self.settings unless @next_instance
    return @next_instance.server_template
  end

  def deployment_href
    hash_of_links["deployment"]
  end

  def current_instance_href
    hash_of_links["current_instance"]
  end

  def cloud_id
    settings unless @next_instance
    cloud_href = @current_instance.hash_of_links["cloud"] if @current_instance
    cloud_href = @next_instance.hash_of_links["cloud"] unless cloud_href
    return cloud_href.split("/").last.to_i
  end

  def dns_name
    self.settings
    ret = nil
    if @current_instance
      ret ||= @current_instance.public_ip_addresses.first
      ret ||= @current_instance.public_dns_names.first
      ret ||= get_tags_by_namespace("server")["current_instance"]["public_ip_0"]
    end
    ret
  end

  def private_ip
    self.settings
    ret = nil
    if @current_instance
      ret ||= @current_instance.private_ip_addresses.first
      ret ||= @current_instance.private_dns_names.first
      ret ||= get_tags_by_namespace("server")["current_instance"]["private_ip_0"]
    end
    ret
  end

  def save
    update
  end

  def update
    @next_instance.update
    @current_instance.update if @current_instance
  end

  def reload_as_current
    settings # Gets all instance (including current) information
  end

  def reload_as_next
    settings # Gets all instance (including current) information
  end

  def get_sketchy_data(params)
    settings
    raise "No current instance found!" unless @current_instance
    @current_instance.get_sketchy_data(params)
  end

  # Override Taggable mixin so that it sets tags on both next and current instances
  def current_tags(reload=true)
    ret = []
    if @current_instance
      ret = McTag.search_by_href(self.current_instance_href).first["tags"].map { |h| h["name"] }
    end
    ret
  end

  def add_tags(*args)
    return false if args.empty?
    args.uniq!
    McTag.set(self.href, args)
    McTag.set(self.current_instance_href, args) if @current_instance
    self.tags(true)
  end

  def remove_tags(*args)
    return false if args.empty?
    args.uniq!
    McTag.unset(self.href, args)
    McTag.unset(self.current_instance_href, args) if @current_instance
    self.tags(true)
  end

  def get_tags_by_namespace(namespace)
    ret = {}
    tags = {"self" => self.tags(true)}
    tags["current_instance"] = self.current_tags if @current_instance
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
    tags.deep_merge! self.current_tags if @current_instance
    tags = tags.select { |tag| tag.start_with?("#{namespace}:") } if namespace
    self.remove_tags(*tags)
  end
end
