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
  def initialize(cloud_id = 1, params = {})
    @multicloud = (cloud_id.to_i > 10 ? true : false)
    @impl = (@multicloud ? McServer.new(params) : Server.new(params))
  end

  def create(opts)
    location = connection.post(resource_plural_name, translate_create_opts(opts))
    @impl = (@multicloud ? McServer.new('href' => location) : Server.new('href' => location))
    reload
    self
  end

  def href
    if @multicloud
      return @impl.href
    else
      return
    end
  end

  def name
    nickname
  end

  def nickname
    param = :nickname
    param = :name if @multicloud
    @impl.__send__(param)
  end

  def method_missing(method_name, *args, &block)
    @impl.__send__(method_name, *args, &block)
  end

  def ruby_1_8_7_keep_if(hsh, &block)
    temp_a = hsh.select &block
    temp_h = {}
    temp_a.each { |array| temp_h[array.first] = array.last }
    hsh.replace(temp_h)
  end

  def deep_duplicate(obj)
    copy = {"Array" => lambda { |array| elem = deep_duplicate(elem) },
            "Hash" => lambda { |key,val|
              key = deep_duplicate(key)
              val = deep_duplicate(val)
            }}
    new_obj = obj.dup.each 
    return new_obj
  end

  def translate_create_opts(old_opts)
    opts = old_opts.dup
    server = {}
    server[:deployment_href] = opts[:deployment_href]
    if @multicloud
      server[:name] = (opts[:nickname] or opts[:name])
      server[:instance] = {}
      server[:instance][:server_template_href] = opts[:server_template_href]
      server[:instance][:cloud_href] = opts[:cloud_href] if opts[:cloud_href]
      server[:instance][:cloud_href] = "https://my.rightscale.com/api/clouds/#{opts[:cloud_id]}" if opts[:cloud_id]
      server[:instance][:multi_cloud_image_href] = (opts[:mci_href] or opts[:multi_cloud_image_href])
      server[:instance][:instance_type_href] = (map_ec2instance_type(opts[:instance_type]) or
                                                opts[:instance_type_href])
      server[:instance][:inputs] = opts[:inputs]
      server[:instance][:user_data] = (opts[:ec2_user_data] or opts[:user_data])
      server[:instance][:image_href] = (opts[:aki_image_href] or opts[:ari_image_href] or opts[:ec2_image_href])
      server[:instance][:security_groups_href] = (opts[:ec2_security_groups_href] or opts[:security_groups_href])
      server[:instance][:ssh_key_href] = (opts[:ec2_ssh_key_href] or opts[:ssh_key_href])
      server[:instance][:datacenter_href] = opts[:datacenter_href]
      server[:instance][:kernel_image_href] = opts[:kernel_image_href]
      server[:instance][:ramdisk_image_href] = opts[:ramdisk_image_href]
      server[:description] = opts[:description]
      ruby_1_8_7_keep_if(server) { |key,val|
        if val.is_a?(Hash)
          val.delete_if { |k,v| v.nil? or v == "" }
          val.each { |k,v| v = translate_href(v) if k.to_s =~ /href/ }
          ret = true
        elsif val.nil? or val == ""
          ret = false
        else
          val = translate_href(val) if key.to_s =~ /href/
          ret = true
        end
        ret
      }
      return {:server => server}
    else #API 1.0
      server[:nickname] = (opts[:nickname] or opts[:name])
      server[:deployment_href] = opts[:deployment_href]
      server[:server_template_href] = opts[:server_template_href]
      server[:aki_image_href] = opts[:aki_image_href]
      server[:ari_image_href] = opts[:ari_image_href]
      server[:ec2_image_href] = opts[:ec2_image_href]
      server[:ec2_user_data] = (opts[:ec2_user_data] or opts[:user_data])
      server[:instance_type] = (opts[:instance_type] or unmap_ec2_instance_href(opts[:instance_type_href]))
      server[:ec2_security_groups_href] = (opts[:ec2_security_groups_href] or opts[:security_groups_href])
      server[:vpc_subnet_href] = opts[:vpc_subnet_href]
      server[:ec2_availability_zone] = opts[:ec2_availability_zone]
      server[:pricing] = opts[:pricing]
      server[:max_spot_price] = opts[:max_spot_price]
      begin
        cloud_id = opts[:cloud_href].split(/\/clouds\//).last
      rescue Exception => e
        cloud_id = opts[:cloud_id]
      end
      ruby_1_8_7_keep_if(server) { |key,val|
        if val.is_a?(Hash)
          val.delete_if { |k,v| v.nil? or v == "" }
          val.each { |k,v| v = translate_href(v) if k.to_s =~ /href/ }
          ret = true
        elsif val.nil? or val == ""
          ret = false
        else
          val = translate_href(val) if key.to_s =~ /href/
          ret = true
        end
        ret
      }
      return {:server => server, :cloud_id => cloud_id}
    end
  end

  def translate_href(href)
    if href.include?("acct") #API 1.0
      return href.gsub!(/\/acct\/[0-9]*/,'').gsub!(/ec2_/,'') if @multicloud
#      my_base_href, @account = href.split(/\/acct\//)
#      @account, *remaining = @account.split(/\//)
#      if @multicloud
#        return my_base_href + "/" + remaining.join("/").gsub(/ec2_/,'')
#      else
#        return href
#      end
#    else #API 1.5
    end
    href
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
