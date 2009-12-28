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
require 'rightscale_api_base'
require 'rightscale_api_resources'

module RestConnection
  class Connection
    attr_accessor :settings

    # settings loaded from yaml include :common_headers
    # :user, :pass, and :api_url
    # you can override them using the settings accessor
    def initialize(config_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml"))
      if File.exists?(config_yaml)
        @settings = YAML::load(IO.read(config_yaml))
      else
        logger("\nWARNING:  no api config found in #{config_yaml}")
        logger("INFO:  see rest_connection/config/rest_api_config.yaml for example config")
        @settings = {}
      end
    end

    def rest_connect(options = {}, &block)
      uri = URI.parse(@settings[:api_url])
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true 
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      headers = @settings[:common_headers]
      http.start do |http|
        req = yield(uri, headers)
        req.basic_auth(@settings[:user], @settings[:pass]) if @settings[:user]
        logger("#{req.method}: #{req.path}")
        logger("\trequest body: #{req.body}") if req.body
        response, body = http.request(req)
        handle_response(response)
      end
    end

    # expects href="servers" for example
    # -or- begins with a slash for absolute path ie: "/api/acct/x/servers"
    def get(href, additional_parameters = "")
      rest_connect do |base_uri,headers|
        href = "#{base_uri}/#{href}" unless begins_with_slash(href)
        new_path = URI.escape(href + '.js?' + requestify(additional_parameters))
        Net::HTTP::Get.new(new_path, headers)
      end
    end

    # expects href="servers" for example
    # -or- begins with a slash for absolute path ie: "/api/acct/x/servers"
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

    def handle_response(res)
      if res.code.to_i == 201
        return res['Location']
      elsif [200,203,204].detect { |d| d == res.code.to_i }
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
      STDERR.puts(message)
    end

    def name_with_prefix(prefix, name)
      prefix ? "#{prefix}[#{name}]" : name.to_s
    end

    def requestify(parameters, prefix=nil)
      if Hash === parameters
        return nil if parameters.empty?
        parameters.map { |k,v| requestify(v, name_with_prefix(prefix, k)) }.join("&")
      elsif Array === parameters
        parameters.map { |v| requestify(v, name_with_prefix(prefix, "")) }.join("&")
      elsif prefix.nil?
        parameters
      else
        "#{CGI.escape(prefix)}=#{CGI.escape(parameters.to_s)}"
      end
    end

  end
end
