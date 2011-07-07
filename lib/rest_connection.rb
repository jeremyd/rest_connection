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

require 'net/https'
require 'rubygems'
require 'json'
require 'yaml'
require 'cgi'
require 'rest_connection/rightscale/rightscale_api_resources'
require 'rest_connection/patches'
require 'logger'
require 'highline/import'

module RestConnection
  AWS_CLOUDS = [{"cloud_id" => 1, "name" => "AWS US-East"},
                {"cloud_id" => 2, "name" => "AWS EU"},
                {"cloud_id" => 3, "name" => "AWS US-West"},
                {"cloud_id" => 4, "name" => "AWS AP-Singapore"},
                {"cloud_id" => 5, "name" => "AWS AP-Tokyo"}]

    # Check for API 0.1 Access
  def self.api0_1?
    unless class_variable_defined?("@@api0_1")
      begin
        Ec2SshKeyInternal.find_all
        @@api0_1 = true
      rescue
        @@api0_1 = false
      end
    end
    return @@api0_1
  end

  # Check for API 1.0 Access
  def self.api1_0?
    unless class_variable_defined?("@@api1_0")
      begin
        Ec2SecurityGroup.find_all
        @@api1_0 = true
      rescue
        @@api1_0 = false
      end
    end
    return @@api1_0
  end

  # Check for API 1.5 Beta Access
  def self.api1_5?
    unless class_variable_defined?("@@api1_5")
      begin
        Cloud.find_all
        @@api1_5 = true
      rescue
        @@api1_5 = false
      end
    end
    return @@api1_5
  end

  class Connection
    # Settings is a hash of options for customizing the connection.
    # settings.merge! {
    # :common_headers => { "X_CUSTOM_HEADER" => "BLAH" },
    # :api_url =>
    # :user =>
    # :pass =>
    attr_accessor :settings, :cookie

    # RestConnection api settings configuration file:
    # Settings are loaded from a yaml configuration file in users home directory.
    # Copy the example config from the gemhome/config/rest_api_config.yaml.sample to ~/.rest_connection/rest_api_config.yaml
    # OR to /etc/rest_connection/rest_api_config.yaml
    #
    def initialize(config_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml"))
      @@logger = nil
      @@user = nil
      @@pass = nil
      etc_config = File.join("#{File::SEPARATOR}etc", "rest_connection", "rest_api_config.yaml")
      if File.exists?(config_yaml)
        @settings = YAML::load(IO.read(config_yaml))
      elsif File.exists?(etc_config)
        @settings = YAML::load(IO.read(etc_config))
      else
        logger("\nWARNING:  you must setup config file rest_api_config.yaml in #{config_yaml} or #{etc_config}")
        logger("WARNING:  see GEM_HOME/rest_connection/config/rest_api_config.yaml for example config")
        @settings = {}
      end
      @settings[:extension] = ".js"
      @settings[:api_href] = @settings[:api_url] unless @settings[:api_href]
      unless @settings[:user]
        @@user = ask("Username:") unless @@user
        @settings[:user] = @@user
      end
      unless @settings[:pass]
        @@pass = ask("Password:") { |q| q.echo = false } unless @@pass
        @settings[:pass] = @@pass
      end
    end

    # Main HTTP connection loop. Common settings are set here, then we yield(BASE_URI, OPTIONAL_HEADERS) to other methods for each type of HTTP request: GET, PUT, POST, DELETE
    # 
    # The block must return a Net::HTTP Request. You have a chance to taylor the request inside the block that you pass by modifying the url and headers.
    #
    # rest_connect do |base_uri, headers|
    #   headers.merge! {:my_header => "blah"}
    #   Net::HTTP::Get.new(base_uri, headers)
    # end
    #   
    def rest_connect(&block)
      uri = URI.parse(@settings[:api_href])
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true 
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      headers = @settings[:common_headers]
      headers.merge!("Cookie" => @cookie) if @cookie 
      http.start do |http|
        req = yield(uri, headers)
        unless @cookie
          req.basic_auth(@settings[:user], @settings[:pass]) if @settings[:user]
        end
        logger("#{req.method}: #{req.path}")
        logger("\trequest body: #{req.body}") if req.body and req.body !~ /password/
        response, body = http.request(req)
        handle_response(response)
      end
    end

    # connection.get("/root/login", :test_header => "x", :test_header2 => "y")
    # href = "/api/base_new" if this begins with a slash then the url will be used as absolute path.
    # href = "servers" this will be concat'd on to the api_url from the settings
    # additional_parameters = Hash or String of parameters to pass to HTTP::Get
    def get(href, additional_parameters = "")
      rest_connect do |base_uri,headers|
        href = "#{base_uri}/#{href}" unless begins_with_slash(href)
        new_path = URI.escape(href + @settings[:extension] + "?") + requestify(additional_parameters)
        Net::HTTP::Get.new(new_path, headers)
      end
    end
    
    # connection.post(server_url + "/start")
    #
    # href = "/api/base_new" if this begins with a slash then the url will be used as absolute path.
    # href = "servers" this will be concat'd on to the api_url from the settings
    # additional_parameters = Hash or String of parameters to pass to HTTP::Post
    def post(href, additional_parameters = {})
      rest_connect do |base_uri, headers|
        href = "#{base_uri}/#{href}" unless begins_with_slash(href)
        res = Net::HTTP::Post.new(href , headers)
        unless additional_parameters.empty?
          res.set_content_type('application/json')
          res.body = additional_parameters.to_json
        end
        #res.set_form_data(additional_parameters, '&')
        res
      end
    end

    # connection.put(server_url + "/start")
    #
    # href = "/api/base" if this begins with a slash then the url will be used as absolute path.
    # href = "servers" this will be concat'd on to the api_url from the settings
    # additional_parameters = Hash or String of parameters to pass to HTTP::Put
    def put(href, additional_parameters = {})
      rest_connect do |base_uri, headers|
        href = "#{base_uri}/#{href}" unless begins_with_slash(href)
        new_path = URI.escape(href)
        req = Net::HTTP::Put.new(new_path, headers) 
        req.set_content_type('application/json')
        req.body = additional_parameters.to_json
        req
      end
    end

    # connection.delete(server_url)
    #
    # href = "/api/base_new" if this begins with a slash then the url will be used as absolute path.
    # href = "servers" this will be concat'd on to the api_url from the settings
    # additional_parameters = Hash or String of parameters to pass to HTTP::Delete
    def delete(href, additional_parameters = {})
      rest_connect do |base_uri, headers|
        href = "#{base_uri}/#{href}" unless begins_with_slash(href)
        new_path = URI.escape(href)
        req = Net::HTTP::Delete.new(href, headers)
        req.set_content_type('application/json')
        req.body = additional_parameters.to_json
        req
      end
    end

    # handle_response
    # res = HTTP response 
    #
    # decoding and post processing goes here. This is where you may need some customization if you want to handle the response differently (or not at all!).  Luckily it's easy to modify based on this handler.
    def handle_response(res)
      if res.code.to_i == 201 or res.code.to_i == 202
        return res['Location']
      elsif [200,203,204,302].detect { |d| d == res.code.to_i }
        if res.body
          begin
            return JSON.load(res.body)
          rescue => e
            return res
          end
        else
          return res
        end
      else 
        raise "invalid response HTTP code: #{res.code.to_i}, #{res.code}, #{res.body}"
      end
    end

    def begins_with_slash(href)
      href =~ /^\//
    end

    def logger(message)
      init_message = "Initializing Logging using "
      if @@logger.nil?
        if ENV['REST_CONNECTION_LOG']
          @@logger = Logger.new(ENV['REST_CONNECTION_LOG'])
          init_message += ENV['REST_CONNECTION_LOG']
        else
          @@logger = Logger.new(STDOUT)
          init_message += "STDOUT"
        end
        @@logger.info(init_message)
      end

      @@logger.info("[API V#{@settings[:common_headers]["X_API_VERSION"]} ]" + message)
    end

    # used by requestify to build parameters strings
    def name_with_prefix(prefix, name)
      prefix ? "#{prefix}[#{name}]" : name.to_s
    end

    # recursive method builds CGI escaped strings from Hashes, Arrays and strings of parameters.
    def requestify(parameters, prefix=nil)
      if Hash === parameters
        return nil if parameters.empty?
        parameters.map { |k,v| requestify(v, name_with_prefix(prefix, k)) }.join("&")
      elsif Array === parameters
        parameters.map { |v| requestify(v, name_with_prefix(prefix, "")) }.join("&")
      elsif prefix.nil?
        parameters
      else
        "#{prefix}=#{CGI.escape(parameters.to_s)}"
      end
    end

  end
end
