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
  
  def launch
    if actions.include?("launch")
      t = URI.parse(self.href)
      connection.post(t.path + '/launch')
    else
      connection.logger("WARNING: was in #{self.state} so skipping launch call")
    end
  end

  def terminate
    if actions.include?("terminate")
      t = URI.parse(self.href)
      connection.post(t.path + '/terminate')
      @current_instance = nil
    else
      connection.logger("WARNING: was in #{self.state} so skipping terminate call")
    end
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

  def set_input(name, value)
    @inputs.multi_update([{'name' => name, 'value' => value}])
  end

  def set_inputs(hash = {})
    @inputs.multi_update(transform_inputs(:to_a, hash))
  end

  def settings #show
    serv_href = URI.parse(self.href)
    @params.merge! connection.get(serv_href.path, 'view' => 'instance_detail')
    @current_instance = McInstance.new(self.current_instance) if self.current_instance
    @next_instance = McInstance.new(self.next_instance)
    @params
  end

  def get_sketchy_data(params = {})
    raise "Congratulations on making it this far into the Multicloud Monkey."
# TODO: Inprogress
#    base_href = self.href.split(/\/server/).first
#    base_href = base_href.split(/\/deployment/).first if base_href.include?(/\/deployment/)
#    @monitors ? @monitors = MonitoringMetric.new('href' => MonitoringMetric.href(find_all(@cloud_id
  end

  def monitoring
    @current_instance.fetch_monitoring_metrics
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

  def tags
    []
  end

  def deployment_href
    hash_of_links["deployment"]
  end

  def current_instance_href
    hash_of_links["current_instance"]
  end

  def wait_for_operational_with_dns(state_wait_timeout=1200)
    timeout = 600
    wait_for_state("operational", state_wait_timeout)
    step = 15
    while(timeout > 0)
      self.settings
      break if self.dns_name
      connection.logger "waiting for a public IP for #{self.nickname}"
      sleep step
      timeout -= step
    end
    connection.logger "got IP: #{self.dns_name}"
    raise "FATAL, this server #{self.audit_link} timed out waiting for DNS" if timeout <= 0
  end

  def dns_name
    if @current_instance
      return @current_instance.public_ip_addresses.first
    end
    nil
  end
end
