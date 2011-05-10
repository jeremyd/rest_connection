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
    module BaseExtend
      def connection()
        @@connection ||= RestConnection::Connection.new
        settings = @@connection.settings
        settings[:common_headers]["X_API_VERSION"] = "1.0"         
        settings[:api_href] = settings[:api_url]
        settings[:extension] = ".js"
        @@connection
      end

      def resource_plural_name
        self.to_s.underscore.pluralize
      end 

      def resource_singular_name
        self.to_s.underscore
      end
      # matches using result of block match expression
      # ex: Server.find_by(:nickname) { |n| n =~ /production/ }
      def find_by(attrib, &block)
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
        connection.logger("DEPRICATION WARNING: use of find_by_nickname is depricated, please use find_by(:nickname) { |n| n == '#{nickname}' } ")
        self.find_by(:nickname) { |n| n == nickname }
      end

      # the argument can be 
      # 1) takes href (URI), 
      # 2) or id (Integer)
      # 3) or symbol :all, :first, :last
      def find(href, &block)
        if href.is_a?(Integer)
          return self.new(connection.get(self.resource_plural_name + "/#{href}"))
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
        connection.logger("DEPRICATION WARNING: use of find_by_id is depricated, please use find(id) ")
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
          filter_params << "#{key}=#{val}"
          }
        a = Array.new
        connection.get(self.resource_plural_name, :filter => filter_params).each do |object|
          a << self.new(object)
        end
        return a
      end

      def [](*args)
        ret = []
        args.each { |arg|
          temp = []
          begin
            temp << (arg.is_a?(Hash) ? find_with_filter(arg) : find(arg))
          rescue
          end
          temp.flatten!
          if temp.empty?
            if arg.is_a?(Hash)
              temp << find_by(arg.keys.first) { |v| v =~ /#{arg.values.first}/ }
            else
              temp << find_by_nickname_speed(arg)
            end
          end
          ret += temp
        }
        return (args.empty? ? find_all : ret.flatten)
      end
    end

    module Base
      # The params hash of attributes for direct manipulation
      attr_accessor :params
      def initialize(params = {})
        @params = params
      end

      def connection()
        @@connection ||= RestConnection::Connection.new
        settings = @@connection.settings
        settings[:common_headers]["X_API_VERSION"] = "1.0"         
        settings[:api_href] = settings[:api_url]
        settings[:extension] = ".js"
        @@connection
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
        try_these = [name, name.to_s.gsub(/_/,'-'), name.to_sym]
        try_these.each do |t|
          if @params[t]
            return @params[t]
          else
            return @params[t]
          end
        end
      end

    end
  end
end
