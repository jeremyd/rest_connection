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

require 'active_support/inflector'

module RightScale
  module Api
    DATETIME_FMT = "%Y/%m/%d %H:%M:%S +0000"
    AWS_CLOUDS = [
      {"cloud_id" => 1, "name" => "AWS US-East"},
      {"cloud_id" => 2, "name" => "AWS EU"},
      {"cloud_id" => 3, "name" => "AWS US-West"},
      {"cloud_id" => 4, "name" => "AWS AP-Singapore"},
      {"cloud_id" => 5, "name" => "AWS AP-Tokyo"},
      {"cloud_id" => 6, "name" => "AWS US-Oregon"},
      {"cloud_id" => 7, "name" => "AWS SA-Sao Paulo"},
    ]

    BASE_COOKIE_REFRESH = proc do
      def refresh_cookie
        # login
        @cookie = nil
        resp = get("login")
        unless resp.code == "302" || resp.code == "204"
          raise "ERROR: Login failed. #{resp.message}. Code:#{resp.code}"
        end
        @cookie = resp.response['set-cookie']
        true
      end
    end

    # Pass no arguments to reset to the default configuration,
    # pass a hash to update the settings for all API Versions
    def self.update_connection_settings(*settings)
      if settings.size > 1
        raise ArgumentError.new("wrong number of arguments (#{settings.size} for 1)")
      end
      konstants = constants.map { |c| const_get(c) }
      konstants.reject! { |c| !(Module === c) }
      konstants.reject! { |c| !(c.instance_methods.include?("connection")) }
      konstants.each do |c|
        c.instance_exec(settings) do |opts|
          class_variable_set("@@connection", RestConnection::Connection.new(*opts))
        end
      end
      @@api0_1, @@api1_0, @@api1_5 = nil, nil, nil
      true
    end

    # Check for API 0.1 Access
    def self.api0_1?
      if class_variable_defined?("@@api0_1")
        return @@api0_1 unless @@api0_1.nil?
      end
      Ec2SshKeyInternal.find_all
      @@api0_1 = true
    rescue RestConnection::Errors::Forbidden
      @@api0_1 = false
    end

    # Check for API 1.0 Access
    def self.api1_0?
      if class_variable_defined?("@@api1_0")
        return @@api1_0 unless @@api1_0.nil?
      end
      Ec2SecurityGroup.find_all
      @@api1_0 = true
    rescue RestConnection::Errors::Forbidden
      @@api1_0 = false
    end

    # Check for API 1.5 Beta Access
    def self.api1_5?
      if class_variable_defined?("@@api1_5")
        return @@api1_5 unless @@api1_5.nil?
      end
      Cloud.find_all
      @@api1_5 = true
    rescue RestConnection::Errors::Forbidden
      @@api1_5 = false
    end

    module BaseConnection
      def connection(*opts)
        @@connection ||= RestConnection::Connection.new(*opts)
        settings = @@connection.settings
        settings[:common_headers]["X_API_VERSION"] = "1.0"
        settings[:api_href] = settings[:api_url]
        settings[:extension] = ".js"

        unless @@connection.respond_to?(:refresh_cookie)
          @@connection.instance_exec(&(RightScale::Api::BASE_COOKIE_REFRESH))
        end

        @@connection.refresh_cookie unless @@connection.cookie
        @@connection
      end
    end

    module BaseExtend
      include RightScale::Api::BaseConnection

      def resource_plural_name
        self.to_s.underscore.pluralize
      end

      def resource_singular_name
        self.to_s.underscore
      end
      # matches using result of block match expression
      # ex: Server.find_by(:nickname) { |n| n =~ /production/ }
      def find_by(attrib, &block)
        attrib = attrib.to_sym
        if self.filters.include?(attrib)
          connection.logger("#{self} includes the filter '#{attrib}', you might be able to speed up this API call")
        end
        self.find_all.select do |s|
          yield(s[attrib.to_s])
        end
      end

      def find_all
        a = Array.new
        connection.get(self.resource_plural_name).each do |object|
          a << self.new(object)
        end
        return a
      end

      def find_by_cloud_id(cloud_id)
        a = Array.new
        connection.get(self.resource_plural_name, "cloud_id" => cloud_id).each do |object|
          a << self.new(object)
        end
        return a
      end

      def find_by_nickname(nickname)
        connection.logger("DEPRECATION WARNING: use of find_by_nickname is deprecated, please use find_by(:nickname) { |n| n == '#{nickname}' } ")
        self.find_by(:nickname) { |n| n == nickname }
      end

      # the argument can be
      # 1) takes href (URI),
      # 2) or id (Integer)
      # 3) or symbol :all, :first, :last
      def find(href, additional_params={}, &block)
        if href.is_a?(Integer)
          return self.new(connection.get(self.resource_plural_name + "/#{href}", additional_params))
        elsif href.is_a?(Symbol)
          results = self.find_all
          if block_given?
            results = results.select { |s| yield(s) }
          end
          if href == :all
            return results
          elsif href == :first
            return results.first
          elsif href == :last
            return results.last
          end
        elsif uri = URI.parse(href)
          return self.new(connection.get(uri.path))
        end
        nil
      end

      def find_by_id(id)
        connection.logger("DEPRECATION WARNING: use of find_by_id is deprecated, please use find(id) ")
        self.find(id)
      end

      def create(opts)
        location = connection.post(self.resource_plural_name, self.resource_singular_name.to_sym => opts)
        newrecord = self.new('href' => location)
        newrecord.reload
        newrecord
      end

      # filter is only implemented on some api endpoints
      def find_by_nickname_speed(nickname)
        self.find_with_filter('nickname' => nickname)
      end

      # filter is only implemented on some api endpoints
      def find_with_filter(filter = {})
        filter_params = []
        filter.each { |key,val|
          unless self.filters.include?(key.to_sym)
            raise ArgumentError.new("#{key} is not a valid filter for resource #{self.resource_singular_name}")
          end
          filter_params << "#{key}=#{val}"
        }
        a = Array.new
        connection.get(self.resource_plural_name, :filter => filter_params).each do |object|
          a << self.new(object)
        end
        return a
      end

      def filters()
        []
      end

      def [](*args)
        ret = []
        args.each { |arg|
          temp = []
          begin
            if arg.is_a?(Hash)
              if arg.keys.first.to_s == "cloud_id"
                temp << find_by_cloud_id(arg.values.first.to_i)
              else
                temp << find_with_filter(arg)
              end
            elsif arg.is_a?(Regexp)
              temp << find_by(:nickname) { |n| n =~ arg }
            else
              temp << find(arg)
            end
          rescue
          end
          temp.flatten!
          if temp.empty?
            all = find_all
            if arg.is_a?(Hash)
              temp << all.select { |v| v.__send__(arg.keys.first.to_sym) =~ /#{arg.values.first}/ }
            elsif arg.is_a?(Regexp)
              temp += all.select { |n| n.name =~ arg }
              temp += all.select { |n| n.nickname =~ arg } if temp.empty?
            else
              temp += all.select { |n| n.name =~ /#{arg}/ }
              temp += all.select { |n| n.nickname =~ /#{arg}/ } if temp.empty?
            end
          end
          ret += temp
        }
        return (args.empty? ? find_all : ret.flatten.uniq)
      end

      def deny_methods(*symbols)
        symbols.map! { |sym| sym.to_sym }
        if symbols.delete(:index)
          symbols |= [:find_all, :find_by, :find_by_cloud_id, :find_by_nickname, :find_by_nickname_speed, :find_with_filter]
        end
        if symbols.delete(:show)
          symbols |= [:show, :reload, :find, :find_by_id]
        end
        if symbols.delete(:update)
          symbols |= [:save, :update]
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

    module Base
      include RightScale::Api::BaseConnection

      # The params hash of attributes for direct manipulation
      attr_accessor :params
      def initialize(params = {})
        @params = params
      end

      def resource_plural_name
        self.class.to_s.underscore.pluralize
      end

      def resource_singular_name
        self.class.to_s.underscore
      end

      def save
        uri = URI.parse(self.href)
        connection.put(uri.path, resource_singular_name.to_sym => @params)
      end

      def reload
        uri = URI.parse(self.href)
        @params ? @params.merge!(connection.get(uri.path)) : @params = connection.get(uri.path)
      end

      def destroy
        my_href = URI.parse(self.href)
        connection.delete(my_href.path)
      end

      # the following two methods are used to access the @params hash in a friendly way
      def method_missing(method_name, *args)
        mn = method_name.to_s
        assignment = mn.gsub!(/=/,"")
        mn_dash = mn.gsub(/_/,"-")
        if @params[mn]
          if assignment
            @params[mn] = args[0]
            @params[mn_dash] = args[0]
          end
          return @params[mn]
        elsif @params[mn_dash]
          if assignment
            @params[mn_dash] = args[0]
            @params[mn] = args[0]
          end
          return @params[mn_dash]
        elsif @params[mn.to_sym]
          return @params[mn.to_sym]
        elsif assignment
          @params[mn] = args[0]
          @params[mn_dash] = args[0]
          return @params[mn]
        else
          return nil
          #raise "called unknown method #{method_name} with #{args.inspect}"
        end
      end

      def [](name)
        try_these = [name.to_s, name.to_s.gsub(/_/,'-'), name.to_sym]
        try_these.each do |t|
          if @params[t]
            return @params[t]
          end
        end
        nil
      end

      def []=(name,val)
        try_these = [name.to_s, name.to_s.gsub(/_/,'-'), name.to_sym]
        try_these.each do |t|
          if @params[t]
            @params[t] = val
          end
        end
        val
      end

      def rs_id
        self.href.split(/\//).last
      end

    end
  end
end
