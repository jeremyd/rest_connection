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

class ServerInterface
  attr_reader :multicloud

  def initialize(cloud_id = 1, params = {})
    @multicloud = (cloud_id.to_i > 10 ? true : false)
    @impl = (@multicloud ? McServer.new(params) : Server.new(params))
  end

  def create(opts)
    location = connection.post(resource_plural_name, translate_create_opts(opts))
    @impl = (@multicloud ? McServer.new('href' => location) : Server.new('href' => location))
    settings
    self
  end

  def name
    nickname
  end

  def nickname
    return @impl.nickname unless @multicloud
    return @impl.name if @multicloud
  end

  def method_missing(method_name, *args, &block)
    @impl.__send__(method_name, *args, &block)
  end

  def clean_and_translate_server_params(it)
    it.each do |k, v|
      clean_and_translate_server_params(v) if v.is_a?(Hash)
    end
    it.reject! { |k, v| v == nil or v == "" }
    it.each { |k, v| it[k] = translate_href(v) if k.to_s =~ /href/ }
    it
  end

  def translate_create_opts(old_opts)
    fields = [{"1.0" => [:server_template_href],      "1.5" => [:server_template_href]},
              {"1.0" => [:cloud_id],                  "fn" => :map_cloud_id,  "1.5" => [:cloud_href]},
              {"1.0" => [:aki_image_href, :ari_image_href, :ec2_image_href],  "1.5" => [:image_href]},
              {"1.0" => [:ec2_user_data],             "1.5" => [:user_data]},
              {"1.0" => [:instance_type],             "fn" => :map_instance,  "1.5" => [:instance_type_href]},
              {"1.0" => [:ec2_security_groups_href],  "1.5" => [:security_group_hrefs]},
              {"1.0" => [:ec2_ssh_key_href],          "1.5" => [:ssh_key_href]},
              {"1.0" => [:vpc_subnet_href]},
              {"1.0" => [:ec2_availability_zone]},
              {"1.0" => [:pricing]},
              {"1.0" => [:max_spot_price]},
              {                                       "1.5" => [:inputs]},
              {                                       "1.5" => [:mci_href, :multi_cloud_image_href]},
              {                                       "1.5" => [:datacenter_href]},
              {                                       "1.5" => [:kernel_image_href]},
              {                                       "1.5" => [:ramdisk_image_href]}]

    opts = old_opts.dup
    if @multicloud
      to = "1.5"
      ret = {:server => {:instance => {}}}
      ret[:server][:name] = (opts[:name] ? opts[:name] : opts[:nickname])
      ret[:server][:description] = opts[:description]
      ret[:server][:deployment_href] = opts[:deployment_href]
      server = ret[:server][:instance]
    else
      to = "1.0"
      server = {:nickname => (opts[:nickname] ? opts[:nickname] : opts[:name])}
      server[:deployment_href] = opts[:deployment_href]
      ret = {:server => server}
      begin
        ret[:cloud_id] = opts[:cloud_href].split(/\/clouds\//).last
      rescue Exception => e
        ret[:cloud_id] = opts[:cloud_id]
      end
    end
    
    fields.each { |hsh|
      next unless hsh[to]
      hsh[to].each { |field|
        vals = opts.select {|k,v| [[hsh["1.0"]] + [hsh["1.5"]]].flatten.include?(k.to_sym) }
        vals.flatten!
        vals.compact!
        if hsh["fn"]
          server[field] = __send__(hsh["fn"], to, opts[vals.first]) unless vals.first.nil?
        else
#          case field
#          when :inputs
#            server[field] = opts[field]
#          when :security_group_hrefs
#            server[field] = opts[field]
#          else
            server[field] = opts[vals.first] unless vals.first.nil?
#          end
        end
      }
    }
    clean_and_translate_server_params(ret)
    return ret
  end

  def map_cloud_id(to, val)
    if val.is_a?(String)
      begin
        val = val.split(/\//).last
      rescue Exception => e
      end
    end
    if to == "1.5"
      return "https://my.rightscale.com/api/clouds/#{val}"
    elsif to == "1.0"
      return "#{val}"
    end
  end

  def map_instance(to, val)
    nil
  end

  def translate_href(old_href)
    if old_href.is_a?(Array)
      new_array = []
      old_href.each { |url| new_array << translate_href(url) }
      return new_array
    else
      href = old_href.dup
      if @multicloud
        href.gsub!(/ec2_/,'')
        href.gsub!(/\/acct\/[0-9]*/,'')
      end
      return href
    end
#    if href.include?("acct")
#      my_base_href, @account = href.split(/\/acct\//)
#      @account, *remaining = @account.split(/\//)
#      if @multicloud
#        return my_base_href + "/" + remaining.join("/").gsub(/ec2_/,'')
#      else
#        return href
#      end
#    else #API 1.5
#    end
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

  def start
    launch
  end

  def stop
    terminate
  end

  def launch
    @impl.launch if @multicloud
    @impl.start unless @multicloud
  end

  def terminate
    @impl.terminate if @multicloud
    @impl.stop unless @multicloud
  end

  def start_ebs
    connection.logger("WARNING: Gateway Servers do not support start_ebs. Ignoring.") if @multicloud
    @impl.start_ebs unless @multicloud
  end

  def stop_ebs
    connection.logger("WARNING: Gateway Servers do not support stop_ebs. Ignoring.") if @multicloud
    @impl.stop_ebs unless @multicloud
  end

  # This should be used with v4 images only.
  def run_script(script,opts=nil)
    connection.logger("WARNING: Gateway Servers do not support run_script. Ignoring.") if @multicloud
    @impl.run_script(script,opts) unless @multicloud
  end 

  def attach_volume(params)
    connection.logger("WARNING: Gateway Servers do not support attach_volume. Ignoring.") if @multicloud
    @impl.attach_volume(params) unless @multicloud
  end

  def get_sketchy_data(params = {})
    @impl.get_sketchy_data(translate_sketchy_params(params))
  end

  def translate_sketchy_params(params)
    return params
    #TODO
#    ret = {}
#    if @multicloud #API 1.5
#      ret['period'] = (ret['period'] or (ret['start']
#    else #API 1.0
#      ret['start'] = 
#    end
#    monitor=server.get_sketchy_data({'start'=>-60,'end'=>-20,'plugin_name'=>"cpu-0",'plugin_type'=>"cpu-idle"})
  end

  def wait_for_state(st,timeout=1200)
    if @multicloud and st == "stopped"
      st = "inactive"
    end
    @impl.wait_for_state(st,timeout)
  end

  # takes Bool argument to wait for state change (insurance that we can detect a reboot happened)
  def reboot(wait_for_state = false)
    connection.logger("WARNING: Gateway Servers do not support reboot. Ignoring.") if @multicloud
    @impl.reboot(wait_for_state) unless @multicloud
  end

  # Save the servers parameters to the current server (instead of the next server)
  def save_current
    connection.logger("WARNING: Gateway Servers do not currently support save_current. Ignoring.") if @multicloud
    @impl.save_current unless @multicloud
  end

  # Load server's settings from the current server (instead of the next server)
  def settings_current
    connection.logger("WARNING: Gateway Servers do not support settings_current. Ignoring.") if @multicloud
    @impl.settings_current unless @multicloud
  end

  # Reload the server's basic information from the current server.
  def reload_current
    connection.logger("WARNING: Gateway Servers do not support reload_current. Ignoring.") if @multicloud
    @impl.reload_current unless @multicloud
  end
end
