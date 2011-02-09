module RightScale
  module Api
    module Gateway
      include RightScale::Api::Base
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
          resp, data = @@gateway_connection.get("session")
          raise "ERROR: Invalid session. #{resp.message}. Code:#{resp.code}" unless resp.code == "200" 
        end
        @@gateway_connection
      end

      def hash_of_links
        ret = {}
        unless @params['links']# and not (@params['nickname'] or @params['name'])
          @params = Kernel.const_get(self.class.to_s).find_by(:name) { |n| n == self.nickname }.first.params
          connection.logger("#{@params.inspect}")
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
          connection.logger("#{@params.inspect}")
        end
        @params['links'].each { |link| ret = link['href'] if link['rel'] == 'self' }
        ret
      end

      def actions
        ret = []
        unless @params['actions']
          raise "Cannot find attribute 'nickname' or 'name' in #{self.inspect}. Aborting." unless self.nickname
          @params = Kernel.const_get(self.class.to_s).find_by(:name) { |n| n == self.nickname }.first.params
          connection.logger("#{@params.inspect}")
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
        try_these = [name, name.to_s.gsub(/_/,'-'), name.to_sym]
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
        try_these = [name, name.to_s.gsub(/_/,'-'), name.to_sym]
        if try_these.include?(:nickname)
          try_these += ["name", :name]
        end
        try_these.each do |t|
          if @params[t]
            @params[t] = val
          elsif hash_of_links[t]
            hash_of_links[t] = val
          end
        end
        val
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
          resp, data = @@gateway_connection.get("session")
          raise "ERROR: Invalid session. #{resp.message}. Code:#{resp.code}" unless resp.code == "200"
        end
        @@gateway_connection
      end

      def find_by(attrib, cloud_id=nil, &block)
        attrib = :name if attrib == :nickname
        self.find_all.select do |s|
          yield(s[attrib.to_s])
        end
      end

      def find_all(cloud_id=nil)
        a = Array.new
        url = self.resource_plural_name
        url = "clouds/#{cloud_id}/#{self.resource_plural_name}" if cloud_id
        connection.get(url).each do |object|
          a << self.new(object)
        end
        return a
      end

      def create(opts)
        location = connection.post(self.resource_plural_name, self.resource_singular_name.to_sym => opts)
        newrecord = self.new('links' => [ {'rel' => 'self', 'href' => location } ])
        newrecord.reload
        newrecord
      end
    end
  end
end
 
