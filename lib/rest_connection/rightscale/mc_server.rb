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
      begin
        connection.post(t.path + '/launch')
      rescue Exception => e
        if connection.settings[:azure_hack_on]
          puts "**** [AZURE_HACK is ON] - McServer.launch() nickname: #{nickname}, caught exception #{e.message}"
          puts "**** connection.settings[:azure_hack_retry_count] = #{connection.settings[:azure_hack_retry_count]}"
          puts "**** connection.settings[:azure_hack_sleep_seconds] = #{connection.settings[:azure_hack_sleep_seconds]}"

          # 504 Gateway should always be treated as a successful launch
          target_504_gateway_timeout_error_message = "504 Gateway Time-out"

          # All 422 exceptions should be retried
          target_422_error_message = "Invalid response HTTP code: 422:"

          if e.message =~ /#{target_504_gateway_timeout_error_message}/
            exception_matched_message = "**** McServer.launch(): Caught #{e.message}, treating as a successful launch..."
            puts(exception_matched_message)
            connection.logger(exception_matched_message)
            true
          elsif e.message =~ /#{target_422_error_message}/
            azure_hack_retry_count = connection.settings[:azure_hack_retry_count]
            exception_matched_message = "**** McServer.launch(): Caught #{e.message}, retrying launch..."
            puts(exception_matched_message)
            connection.logger(exception_matched_message)

            retry_count = 1
            loop do
              # sleep for azure_hack_sleep_seconds seconds
              sleep_message = "**** McServer.launch(): Sleeping for #{connection.settings[:azure_hack_sleep_seconds]} seconds and then retrying (#{retry_count}) launch..."
              puts(sleep_message)
              connection.logger(sleep_message)
              sleep(connection.settings[:azure_hack_sleep_seconds])

              # retry the launch
              begin
                connection.post(t.path + '/launch')
              rescue Exception => e2
                exception_caught_message = "**** McServer.launch(): Retry caught #{e2.message}..."
                puts(exception_caught_message)
                connection.logger(exception_caught_message)

                if e2.message =~ /#{target_422_error_message}/
                  azure_hack_retry_count -= 1
                  if azure_hack_retry_count > 0
                    retry_count += 1

                    # Try again on next iteration
                    next
                  else
                    # Azure Hack maximum retries exceeded so rethrow the new 422 exception
                    raise
                  end
                else
                  # On this re-launch we got some other exception so rethrow it
                  raise
                end
              end

              # Fell through so launch worked and we need to break out of the retry do loop
              break
            end
          else
            # Didn't match on any target exception so rethrow the original exception
            raise
          end
        else
          # Azure Hack isn't enabled so rethrow the original exception
          raise
        end
      end
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

  def run_executable(executable, opts=nil, ignore_lock=false)
    raise "Instance isn't running; Can't run executable" unless @current_instance
    @current_instance.run_executable(executable, opts, ignore_lock)
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

  # *timeout <~Integer> optional, how long to wait for the inactive state before declare failure (in seconds).
  def relaunch(timeout=1200)
    self.terminate
    self.wait_for_state("inactive", timeout)
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
