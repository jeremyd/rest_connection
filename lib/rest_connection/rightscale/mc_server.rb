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
  
  def self.create(opts)
    location = connection.post(self.resource_plural_name, {self.resource_singular_name.to_sym => opts})
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord
  end

  def initialize(params)
    @params = params
    if @params[:server]
      @instance = McInstance.create(@params[:server][:instance])
      if @params[:server][:instance]
        @inputs = Inputs.create(@params[:server][:instance][:inputs])
      end
    end
#    @monitor = MonitoringMetrics.create(@params[:
  end

  def launch
    if @instance.state == "stopped"
      t = URI.parse(self.href)
      connection.post(t.path + '/launch')
    else
      connection.logger("WARNING: was in #{self.state} so skipping launch call")
    end
  end

  def terminate
    if @instance.href
      t = URI.parse(self.href)
      connection.post(t.path + '/terminate')
    else
      connection.logger("WARNING: was in #{self.state} so skipping launch call")
    end
  end
  
  def start #start_ebs
    raise "You shouldn't be here."
  end

  def stop #stop_ebs
    raise "You shouldn't be here."
  end

  def run_executable(executable, opts=nil)
    connection.logger("Congratulations on making it this far into the Multicloud Monkey.")
    raise "Congratulations on making it this far into the Multicloud Monkey."
  end

  def transform_parameters(sym, parameters)
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
    @inputs.multi_update(transform_parameters(:to_a, hash))
  end

  def settings
    serv_href = URI.parse(self.href)
    @params.merge! connection.get(serv_href.path, 'view' => 'full')
    @params[:server][:instance].merge! @instance.show
    @params[:server][:instance][:inputs].merge! @inputs.show
#    @monitoring update
    @params
  end

  def get_sketchy_data(params = {})
    connection.logger("Congratulations on making it this far into the Multicloud Monkey.")
    raise "Congratulations on making it this far into the Multicloud Monkey."
# TODO: Inprogress
#    base_href = self.href.split(/\/server/).first
#    base_href = base_href.split(/\/deployment/).first if base_href.include?(/\/deployment/)
#    @monitors ? @monitors = MonitoringMetric.new('href' => MonitoringMetric.href(find_all(@cloud_id
  end

  def monitoring
    get_sketchy_data ? true : false
  end

  def relaunch
    self.terminate
    self.wait_for_state("stopped")
    self.launch
  end
end
