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

module RightScale
  module Api

    #
    # Refresh cookie by logging in again
    #
    GATEWAY_COOKIE_REFRESH = proc do
      def refresh_cookie
        # login
        ignored, account = @settings[:api_url].split(/\/acct\//) if @settings[:api_url].include?("acct")
        params = {
          "email" => @settings[:user],
          "password" => @settings[:pass],
          "account_href" => "/api/accounts/#{account}"
        }
        @cookie = nil
        resp = post("session", params)
        unless resp.code == "302" || resp.code == "204"
          raise "ERROR: Login failed. #{resp.message}. Code:#{resp.code}"
        end
        # TODO: handle 302 redirects
        @cookie = resp.response['set-cookie']

        # test session
        resp = get("session")
        raise "ERROR: Invalid session. #{resp["message"]}." unless resp.is_a?(Hash)
        true
      end
    end

    module GatewayConnection

      #
      # Config for API 1.5
      #
      def connection(*opts)
        @@gateway_connection ||= RestConnection::Connection.new(*opts)
        settings = @@gateway_connection.settings
        settings[:common_headers]["X_API_VERSION"] = "1.5"
        settings[:api_href], account = settings[:api_url].split(/\/acct\//) if settings[:api_url].include?("acct")
        settings[:extension] = ".json"

        unless @@gateway_connection.respond_to?(:refresh_cookie)
          @@gateway_connection.instance_exec(&(RightScale::Api::GATEWAY_COOKIE_REFRESH))
        end

        @@gateway_connection.refresh_cookie unless @@gateway_connection.cookie
        @@gateway_connection
      end
    end

    module Gateway
      include RightScale::Api::Base
      include RightScale::Api::GatewayConnection

      def initialize(params = {})
        @params = parse_params(params)
      end

      def parse_params(params = {})
        params
      end

      def nickname
        raise TypeError.new("@params isn't a Hash! @params.to_s=#{@params.to_s}") unless @params.is_a?(Hash)
        @params["nickname"] || @params["name"]
      end

      def rediscover
        self.reload if @params['href']
        raise "Cannot find attribute 'nickname' or 'name' in #{self.inspect}. Aborting." unless self.nickname
        if self.class.filters.include?(:name)
          @params = self.class.find_with_filter(:name => self.nickname).first.params
        else
          @params = self.class.find_by(:name) { |n| n == self.nickname }.first.params
        end
      end

      def hash_of_links
        ret = {}
        self.rediscover unless @params['links']
        @params['links'].each { |link| ret[link['rel']] = link['href'] } if @params['links']
        ret
      end

      def href
        return @params['href'] if @params['href']
        ret = nil
        self.rediscover unless @params['links']
        @params['links'].each { |link| ret = link['href'] if link['rel'] == 'self' }
        ret
      end

      def actions
        ret = []
        self.rediscover unless @params['actions']
        @params['actions'].each { |action| ret << action['rel'] }
        ret
      end

      def save
        update
      end

      def method_missing(method_name, *args)
        puts "DEBUG: method_missing in #{self.class.to_s}: #{method_name.to_s}" if ENV['REST_CONNECT_DEBUG']
        mn = method_name.to_s
        assignment = mn.gsub!(/=/,"")
        mn_dash = mn.gsub(/_/,"-")
        if self[mn]
          if assignment
            self[mn] = args[0]
            self[mn_dash] = args[0]
          end
          return self[mn]
        elsif self[mn_dash]
          if assignment
            self[mn_dash] = args[0]
            self[mn] = args[0]
          end
          return self[mn_dash]
        elsif self[mn.to_sym]
          return self[mn.to_sym]
        elsif assignment
          self[mn] = args[0]
          self[mn_dash] = args[0]
          return self[mn]
        else
          return nil
          warn "!!!! WARNING - called unknown method #{method_name.to_s}# with #{args.inspect}"
          #raise "called unknown method #{method_name.to_s}# with #{args.inspect}"
        end
      end

      def [](name)
        try_these = [name.to_s, name.to_s.gsub(/_/,'-'), name.to_sym]
        if try_these.include?(:nickname)
          try_these += ["name", :name]
        end
        try_these.each do |t|
          if @params[t]
            return @params[t]
          elsif hash_of_links[t]
            return hash_of_links[t]
          end
        end
        return nil
      end

      def []=(name,val)
        try_these = [name.to_s, name.to_s.gsub(/_/,'-'), name.to_sym]
        if try_these.include?(:nickname)
          try_these += ["name", :name]
        end
        try_these.each do |t|
          if @params[t]
            @params[t] = val
          elsif hash_of_links[t]
            @params['links'].each { |link|
              link['href'] = val if link['rel'] == t
            }
          end
        end
        val
      end

      def load(resource)
        mod = RightScale::Api::GatewayExtend
        @@gateway_resources ||= Object.constants.map do |const|
          klass = Object.const_get(const)
          (mod === klass ? klass : nil)
        end.compact
        pp @@gateway_resources
        if mod === resource
          klass = resource
        elsif resource.is_a?(String) or resource.is_a?(Symbol)
          klass = @@gateway_resources.detect do |const|
            [const.resource_singular_name, const.resource_plural_name].include?(resource.to_s)
          end
        elsif Class === resource
          raise TypeError.new("#{resource} doesn't extend #{mod}")
        else
          raise TypeError.new("can't convert #{resource.class} into supported Class")
        end

        if self[klass.resource_singular_name]
          return klass.load(self[klass.resource_singular_name])
        elsif self[klass.resource_plural_name]
          return klass.load_all(self[klass.resource_plural_name])
        else
          raise NameError.new("no resource_hrefs found for #{klass}")
        end
      end
    end

    module GatewayExtend
      include RightScale::Api::BaseExtend
      include RightScale::Api::GatewayConnection

      def find_by(attrib, *args, &block)
        attrib = attrib.to_sym
        attrib = :name if attrib == :nickname
        if self.filters.include?(attrib)
          connection.logger("#{self} includes the filter '#{attrib}', you might be able to speed up this API call")
        end
        self.find_all(*args).select do |s|
          yield(s[attrib.to_s])
        end
      end

      def find(*args)
        if args.length > 1
          id = args.pop
          url = "#{parse_args(*args)}#{self.resource_plural_name}/#{id}"
          return self.new(connection.get(url))
        else
          return super(*args)
        end
      end

      def find_all(*args)
        a = Array.new
        url = "#{parse_args(*args)}#{self.resource_plural_name}"
        connection.get(url).each do |object|
          a << self.new(object)
        end
        return a
      end

      def find_with_filter(*args)
        filter_params = []
        filter = {}
        filter = args.pop if args.last.is_a?(Hash)
        filter.each { |key,val|
          unless self.filters.include?(key.to_sym)
            raise ArgumentError.new("#{key} is not a valid filter for resource #{self.resource_singular_name}")
          end
          filter_params << "#{key}==#{val}"
        }
        a = Array.new
        url = "#{parse_args(*args)}#{self.resource_plural_name}"
        connection.get(url, :filter => filter_params).each do |object|
          a << self.new(object)
        end
        return a
      end

      def load(url)
        return self.new(connection.get(url))
      end

      def load_all(url)
        a = Array.new
        connection.get(url).each do |object|
          a << self.new(object)
        end
        return a
      end

      def parse_args()
        nil
      end

      def filters()
        []
      end

      # Hack for McMultiCloudImageSetting class to fix a API quirk
      def resource_post_name
        self.resource_singular_name
      end

      def create(*args)
        if args.last.is_a?(Hash)
          opts = args.pop
        else
          raise ArgumentError.new("create requires the last argument to be a Hash")
        end
        url = "#{parse_args(*args)}#{self.resource_plural_name}"
        location = connection.post(url, self.resource_post_name.to_sym => opts)
        newrecord = self.new('links' => [ {'rel' => 'self', 'href' => location } ])
        newrecord.reload
        newrecord
      end
    end
  end
end

