module RightScale
  module Api
    module Gateway
      include RightScale::Api::Base

      def initialize(params = {})
        @params = parse_params(params)
      end

      def parse_params(params = {})
        params
      end

      def connection
        @@gateway_connection ||= RestConnection::Connection.new
        settings = @@gateway_connection.settings
        settings[:common_headers]["X_API_VERSION"] = "1.5"
        settings[:api_href], account = settings[:api_url].split(/\/acct\//) if settings[:api_url].include?("acct")
        settings[:extension] = ".json"
        unless @@gateway_connection.cookie
          # login
          params = { "email" => settings[:user], "password" => settings[:pass], "account_href" => "/api/accounts/#{account}" }
          resp = @@gateway_connection.post("session", params)
          raise "ERROR: Login failed. #{resp.message}. Code:#{resp.code}" unless resp.code == "302" || resp.code == "204"
          @@gateway_connection.cookie = resp.response['set-cookie']

          # test session
          resp = @@gateway_connection.get("session")
          raise "ERROR: Invalid session. #{resp["message"]}." unless resp.is_a?(Hash)
        end
        @@gateway_connection
      end

      def hash_of_links
        ret = {}
        unless @params['links']# and not (@params['nickname'] or @params['name'])
          @params = Kernel.const_get(self.class.to_s).find_by(:name) { |n| n == self.nickname }.first.params
          connection.logger("in hash_of_links: @params = #{@params.inspect}") if ENV['REST_CONNECT_DEBUG']
        end
        @params['links'].each { |link| ret[link['rel']] = link['href'] } if @params['links']
        ret
      end

      def href
        return @params['href'] if @params['href']
        ret = nil
        unless @params['links']
          raise "Cannot find attribute 'nickname' or 'name' in #{self.inspect}. Aborting." unless self.nickname
          @params = Kernel.const_get(self.class.to_s).find_by(:name) { |n| n == self.nickname }.first.params
          connection.logger("in href: @params = #{@params.inspect}") if ENV['REST_CONNECT_DEBUG']
        end
        @params['links'].each { |link| ret = link['href'] if link['rel'] == 'self' }
        ret
      end

      def actions
        ret = []
        unless @params['actions']
          raise "Cannot find attribute 'nickname' or 'name' in #{self.inspect}. Aborting." unless self.nickname
          @params = Kernel.const_get(self.class.to_s).find_by(:name) { |n| n == self.nickname }.first.params
          connection.logger("in actions: @params = #{@params.inspect}") if ENV['REST_CONNECT_DEBUG']
        end
        @params['actions'].each { |action| ret << action['rel'] }
        ret
      end

      def save
        update
      end

      def method_missing(method_name, *args)
        puts "DEBUG: method_missing in #{self.class.to_s}: #{method_name}" if ENV['REST_CONNECT_DEBUG']
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
          #raise "called unknown method #{method_name} with #{args.inspect}"
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
        if resource.is_a?(Class)
          param_string = resource.resource_singular_name
          class_name = resource
        elsif resource.is_a?(String) or resource.is_a?(Symbol)
          param_string = resource
          begin
            class_name = Kernel.const_get(resource.singularize.camelize)
          rescue
            class_name = Kernel.const_get("Mc#{resource.singularize.camelize}")
          end
        end
        if self[param_string].nil?
          return class_name.load_all(self[param_string.pluralize])
        elsif param_string.pluralize == param_string
          return class_name.load_all(self[param_string])
        else
          return class_name.load(self[param_string])
        end
      end
    end

    module GatewayExtend
      include RightScale::Api::BaseExtend
      def connection
        @@gateway_connection ||= RestConnection::Connection.new
        settings = @@gateway_connection.settings
        settings[:common_headers]["X_API_VERSION"] = "1.5"
        settings[:api_href], account = settings[:api_url].split(/\/acct\//) if settings[:api_url].include?("acct")
        settings[:extension] = ".json"
        unless @@gateway_connection.cookie
          # login
          params = { "email" => settings[:user], "password" => settings[:pass], "account_href" => "/api/accounts/#{account}" }
          resp = @@gateway_connection.post("session", params)
          raise "ERROR: Login failed. #{resp.message}. Code:#{resp.code}" unless resp.code == "302" || resp.code == "204"
          @@gateway_connection.cookie = resp.response['set-cookie']

          # test session
          resp = @@gateway_connection.get("session")
          raise "ERROR: Invalid session. #{resp["message"]}." unless resp.is_a?(Hash)
        end
        @@gateway_connection
      end

      def find_by(attrib, *args, &block)
        attrib = :name if attrib == :nickname
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
#        self.find_with_filter(*args, {})
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

      def create(opts)
        location = connection.post(self.resource_plural_name, self.resource_singular_name.to_sym => opts)
        newrecord = self.new('links' => [ {'rel' => 'self', 'href' => location } ])
        newrecord.reload
        newrecord
      end

      def deny_methods(*symbols)
        symbols.map! { |sym| sym.to_sym }
        if symbols.delete(:index)
          symbols |= [:find_all, :find_by, :find_by_cloud_id, :find_by_nickname, :find_by_nickname_speed, :find_with_filter]
        end
        if symbols.delete(:show)
          symbols |= [:show, :reload, :find, :find_by_id]
        end
        symbols.each do |sym|
          sym = sym.to_sym
          eval_str = "undef #{sym.inspect}"
          if self.respond_to?(sym)
            instance_eval(eval_str)
          elsif self.new.respond_to?(sym)
            class_eval(eval_str)
          end
        end
      end
    end
  end
end

