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
# API 1.5
#
class McInstance
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend
  include RightScale::Api::McTaggable
  extend RightScale::Api::McTaggableExtend
  include RightScale::Api::McInput
  attr_accessor :monitoring_metrics

  deny_methods :create, :destroy

  def resource_plural_name
    "instances"
  end

  def resource_singular_name
    "instance"
  end

  def self.resource_plural_name
    "instances"
  end

  def self.resource_singular_name
    "instance"
  end

  def self.parse_args(cloud_id)
    "clouds/#{cloud_id}/"
  end

  def self.filters
    [
      :datacenter_href,
      :deployment_href,
      :name,
      :os_platform,
      :parent_href,
      :private_dns_name,
      :private_ip_address,
      :public_dns_name,
      :public_ip_address,
      :resource_uid,
      :server_template_href,
      :state
    ]
  end

  def show
    inst_href = URI.parse(self.href)
    @params.merge! connection.get(inst_href.path, 'view' => "full")
  end

  def save
    update
  end

  def map_security_groups(to, sg_ary)
    sg_ary.map { |hsh| hsh["href"] }
  end

  def map_user_data(to, user_data)
    user_data
  end

  def update
    fields = [{"attr" => :datacenter,                                       "api" => :datacenter_href},
              {"attr" => :image,                                            "api" => :image_href},
              {"attr" => :instance_type,                                    "api" => :instance_type_href},
              {                                                             "api" => :kernel_image_href},
              {"attr" => :multi_cloud_image,                                "api" => :multi_cloud_image_href},
              {                                                             "api" => :ramdisk_image_href},
              {"attr" => :security_groups,    "fn" => :map_security_groups, "api" => :security_group_hrefs},
              {"attr" => :server_template,                                  "api" => :server_template_href},
              {"attr" => :ssh_key,                                          "api" => :ssh_key_href},
              {"attr" => :user_data,          "fn" => :map_user_data,       "api" => :user_data}]

    opts = {"instance" => {}}
    instance = opts["instance"]
    to = "api"
    from = "attr"
    fields.each { |hsh|
      next unless hsh[from]
      val = self[hsh[from]]
      if hsh["fn"]
        instance[hsh[to].to_s] = __send__(hsh["fn"], to, val) unless val.nil? || val.empty?
      else
        instance[hsh[to].to_s] = val unless val.nil? || val.empty?
      end
    }
    inst_href = URI.parse(self.href)
    connection.put(inst_href.path, opts)
  end

  def launch
    inst_href = URI.parse(self.href)
    connection.post(inst_href.path + '/launch')
  end

  def terminate
    inst_href = URI.parse(self.href)
    connection.post(inst_href.path + '/terminate')
  end

  def multi_update(input_ary)
    inst_href = URI.parse(self.href)
    connection.put(inst_href.path + '/inputs/multi_update', {'inputs' => input_ary})
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

  def translate_href(old_href)
    href = old_href.dup
    href.gsub!(/ec2_/,'')
    href.gsub!(/\/acct\/[0-9]*/,'')
    return href
  end

  def run_executable(executable, opts=nil, ignore_lock=false)
    run_options = Hash.new
    if executable.is_a?(Executable)
      if executable.recipe?
        run_options[:recipe_name] = executable.recipe
      else
        run_options[:right_script_href] = translate_href(executable.right_script.href)
      end
    elsif executable.is_a?(RightScript)
      run_options[:right_script_href] = translate_href(executable.href)
    else
      raise "Invalid class passed to run_executable, needs Executable or RightScript, was:#{executable.class}"
    end

    if not opts.nil? and opts.has_key?(:ignore_lock)
      run_options[:ignore_lock] = "true"
      opts.delete(:ignore_lock)
      opts = nil if opts.empty?
    end

    inst_href = URI.parse(self.href)
    run_options[:inputs] = transform_inputs(:to_a, opts) unless opts.nil?
    run_options[:ignore_lock] = "true" if ignore_lock
    location = connection.post(inst_href.path + '/run_executable', run_options)
    Task.new('href' => location)
  end

  def fetch_monitoring_metrics
    @monitoring_metrics = []
    return @monitoring_metrics if self.state != "operational"
    connection.get(URI.parse(self.href).path + '/monitoring_metrics').each { |mm|
      @monitoring_metrics << MonitoringMetric.new(mm)
    }
    @monitoring_metrics
  end

  def get_sketchy_data(params)
    metric = fetch_monitoring_metrics.detect { |mm| mm.plugin == params['plugin_name'] and mm.view == params['plugin_type'] }
    raise "Metric not found!" unless metric
    metric.data(params['start'], params['end'])
  end

  def get_data(params)
    get_sketchy_data(params)
  end

  def reboot
    self.show
    connection.post(URI.parse(self.href).path + '/reboot')
  end
end
