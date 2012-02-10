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
    # Here's an example of overriding the settings in the configuration file:
    #   Server.connection.settings[:api_url] = "https://my.rightscale.com/api/acct/1234"
    #
    def initialize(config_yaml = File.join(File.expand_path("~"), ".rest_connection", "rest_api_config.yaml"))
      @@logger = nil
      @@user = nil
      @@pass = nil
      etc_config = File.join("#{File::SEPARATOR}etc", "rest_connection", "rest_api_config.yaml")
      app_bin_dir = File.expand_path(File.dirname(caller.last))
      app_yaml = File.join(app_bin_dir,"..","config","rest_api_config.yaml")
      if config_yaml.is_a?(Hash)
        @settings = config_yaml
      elsif File.exists?(app_yaml)
        @settings = YAML::load(IO.read(app_yaml))
      elsif File.exists?(config_yaml)
        @settings = YAML::load(IO.read(config_yaml))
      elsif File.exists?(etc_config)
        @settings = YAML::load(IO.read(etc_config))
      else
        logger("\nWARNING:  you must setup config file rest_api_config.yaml in #{app_yaml} or #{config_yaml} or #{etc_config}")
        logger("WARNING:  see GEM_HOME/rest_connection/config/rest_api_config.yaml for example config")
        @settings = {}
      end
      @settings.keys.each { |k| @settings[k.to_sym] = @settings[k] if String === k }

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
      http.start do |http|
        @max_retries = 3
        ret = nil
        begin
          headers.delete("Cookie")
          headers.merge!("Cookie" => @cookie) if @cookie
          req = yield(uri, headers)
          logger("#{req.method}: #{req.path}")
          logger("\trequest body: #{req.body}") if req.body and req.body !~ /password/
          req.basic_auth(@settings[:user], @settings[:pass]) if @settings[:user] unless @cookie

          response, body = http.request(req)
          ret = handle_response(response)
        rescue Exception => e
          raise unless error_handler(e)
          retry
        end
        ret
      end
    end

    def error_handler(e)
      case e
      when EOFError, Timeout::Error
        if @max_retries >= 0
          logger("Caught #{e}. Retrying...")
          @max_retries -= 1
          return true
        end
      when RestConnection::Errors::Forbidden
        if @max_retries >= 0
          if e.response.body =~ /(session|cookie).*(invalid|expired)/i
            logger("Caught '#{e.response.body}'. Refreshing cookie...")
            refresh_cookie if respond_to?(:refresh_cookie)
          else
            return false
          end
          @max_retries -= 1
          return true
        end
      end
      return false
    end

    # connection.get("/root/login", :test_header => "x", :test_header2 => "y")
    # href = "/api/base_new" if this begins with a slash then the url will be used as absolute path.
    # href = "servers" this will be concat'd on to the api_url from the settings
    # additional_parameters = Hash or String of parameters to pass to HTTP::Get
    def get(href, additional_parameters = "")
      rest_connect do |base_uri,headers|
        new_href = (href =~ /^\// ? href : "#{base_uri}/#{href}")
        params = requestify(additional_parameters) || ""
        new_path = URI.escape(new_href + @settings[:extension] + "?") + params
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
        new_href = (href =~ /^\// ? href : "#{base_uri}/#{href}")
        res = Net::HTTP::Post.new(new_href , headers)
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
        new_href = (href =~ /^\// ? href : "#{base_uri}/#{href}")
        new_path = URI.escape(new_href)
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
        new_href = (href =~ /^\// ? href : "#{base_uri}/#{href}")
        new_path = URI.escape(new_href)
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
        raise RestConnection::Errors.status_error(res)
      end
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

      if @settings.nil?
        @@logger.info(message)
      else
        @@logger.info("[API v#{@settings[:common_headers]['X_API_VERSION']}] " + message)
      end
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

  module Errors
    # HTTPStatusErrors, borrowed lovingly from the excon gem <3
    class HTTPStatusError < StandardError
      attr_reader :request, :response

      def initialize(msg, response = nil, request = nil)
        super(msg)
        @request = request
        @response = response
      end
    end

    class Continue < HTTPStatusError; end                     # 100
    class SwitchingProtocols < HTTPStatusError; end           # 101
    class OK < HTTPStatusError; end                           # 200
    class Created < HTTPStatusError; end                      # 201
    class Accepted < HTTPStatusError; end                     # 202
    class NonAuthoritativeInformation < HTTPStatusError; end  # 203
    class NoContent < HTTPStatusError; end                    # 204
    class ResetContent < HTTPStatusError; end                 # 205
    class PartialContent < HTTPStatusError; end               # 206
    class MultipleChoices < HTTPStatusError; end              # 300
    class MovedPermanently < HTTPStatusError; end             # 301
    class Found < HTTPStatusError; end                        # 302
    class SeeOther < HTTPStatusError; end                     # 303
    class NotModified < HTTPStatusError; end                  # 304
    class UseProxy < HTTPStatusError; end                     # 305
    class TemporaryRedirect < HTTPStatusError; end            # 307
    class BadRequest < HTTPStatusError; end                   # 400
    class Unauthorized < HTTPStatusError; end                 # 401
    class PaymentRequired < HTTPStatusError; end              # 402
    class Forbidden < HTTPStatusError; end                    # 403
    class NotFound < HTTPStatusError; end                     # 404
    class MethodNotAllowed < HTTPStatusError; end             # 405
    class NotAcceptable < HTTPStatusError; end                # 406
    class ProxyAuthenticationRequired < HTTPStatusError; end  # 407
    class RequestTimeout < HTTPStatusError; end               # 408
    class Conflict < HTTPStatusError; end                     # 409
    class Gone < HTTPStatusError; end                         # 410
    class LengthRequired < HTTPStatusError; end               # 411
    class PreconditionFailed < HTTPStatusError; end           # 412
    class RequestEntityTooLarge < HTTPStatusError; end        # 413
    class RequestURITooLong < HTTPStatusError; end            # 414
    class UnsupportedMediaType < HTTPStatusError; end         # 415
    class RequestedRangeNotSatisfiable < HTTPStatusError; end # 416
    class ExpectationFailed < HTTPStatusError; end            # 417
    class UnprocessableEntity < HTTPStatusError; end          # 422
    class InternalServerError < HTTPStatusError; end          # 500
    class NotImplemented < HTTPStatusError; end               # 501
    class BadGateway < HTTPStatusError; end                   # 502
    class ServiceUnavailable < HTTPStatusError; end           # 503
    class GatewayTimeout < HTTPStatusError; end               # 504

    # Messages for nicer exceptions, from rfc2616
    def self.status_error(response)
      @errors ||= {
        100 => [RestConnection::Errors::Continue, 'Continue'],
        101 => [RestConnection::Errors::SwitchingProtocols, 'Switching Protocols'],
        200 => [RestConnection::Errors::OK, 'OK'],
        201 => [RestConnection::Errors::Created, 'Created'],
        202 => [RestConnection::Errors::Accepted, 'Accepted'],
        203 => [RestConnection::Errors::NonAuthoritativeInformation, 'Non-Authoritative Information'],
        204 => [RestConnection::Errors::NoContent, 'No Content'],
        205 => [RestConnection::Errors::ResetContent, 'Reset Content'],
        206 => [RestConnection::Errors::PartialContent, 'Partial Content'],
        300 => [RestConnection::Errors::MultipleChoices, 'Multiple Choices'],
        301 => [RestConnection::Errors::MovedPermanently, 'Moved Permanently'],
        302 => [RestConnection::Errors::Found, 'Found'],
        303 => [RestConnection::Errors::SeeOther, 'See Other'],
        304 => [RestConnection::Errors::NotModified, 'Not Modified'],
        305 => [RestConnection::Errors::UseProxy, 'Use Proxy'],
        307 => [RestConnection::Errors::TemporaryRedirect, 'Temporary Redirect'],
        400 => [RestConnection::Errors::BadRequest, 'Bad Request'],
        401 => [RestConnection::Errors::Unauthorized, 'Unauthorized'],
        402 => [RestConnection::Errors::PaymentRequired, 'Payment Required'],
        403 => [RestConnection::Errors::Forbidden, 'Forbidden'],
        404 => [RestConnection::Errors::NotFound, 'Not Found'],
        405 => [RestConnection::Errors::MethodNotAllowed, 'Method Not Allowed'],
        406 => [RestConnection::Errors::NotAcceptable, 'Not Acceptable'],
        407 => [RestConnection::Errors::ProxyAuthenticationRequired, 'Proxy Authentication Required'],
        408 => [RestConnection::Errors::RequestTimeout, 'Request Timeout'],
        409 => [RestConnection::Errors::Conflict, 'Conflict'],
        410 => [RestConnection::Errors::Gone, 'Gone'],
        411 => [RestConnection::Errors::LengthRequired, 'Length Required'],
        412 => [RestConnection::Errors::PreconditionFailed, 'Precondition Failed'],
        413 => [RestConnection::Errors::RequestEntityTooLarge, 'Request Entity Too Large'],
        414 => [RestConnection::Errors::RequestURITooLong, 'Request-URI Too Long'],
        415 => [RestConnection::Errors::UnsupportedMediaType, 'Unsupported Media Type'],
        416 => [RestConnection::Errors::RequestedRangeNotSatisfiable, 'Request Range Not Satisfiable'],
        417 => [RestConnection::Errors::ExpectationFailed, 'Expectation Failed'],
        422 => [RestConnection::Errors::UnprocessableEntity, 'Unprocessable Entity'],
        500 => [RestConnection::Errors::InternalServerError, 'InternalServerError'],
        501 => [RestConnection::Errors::NotImplemented, 'Not Implemented'],
        502 => [RestConnection::Errors::BadGateway, 'Bad Gateway'],
        503 => [RestConnection::Errors::ServiceUnavailable, 'Service Unavailable'],
        504 => [RestConnection::Errors::GatewayTimeout, 'Gateway Timeout']
      }
      error, message = @errors[response.code.to_i] || [RestConnection::Errors::HTTPStatusError, 'Unknown']
      error.new("Invalid response HTTP code: #{response.code.to_i}: #{response.body}", response)
    end
  end
end
