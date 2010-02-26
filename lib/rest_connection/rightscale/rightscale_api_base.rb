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

require 'rest_connection/mechanize_connection'
require 'active_support'

module RightScale
  module Api
    class Base
      include MechanizeConnection::Connection
      # The params hash of attributes for direct manipulation
      attr_accessor :params

      def self.connection()
        @@connection ||= RestConnection::Connection.new
      end
      def connection()
        @@connection ||= RestConnection::Connection.new
      end

      def initialize(params = {})
        @params = params
      end

      def self.resource_plural_name
        self.to_s.underscore.pluralize
      end 

      def self.resource_singluar_name
        self.to_s.underscore
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

      # matches using result of block match expression
      # ex: Server.find_by(:nickname) { |n| n =~ /production/ }
      def self.find_by(attrib, &block)
        self.find_all.select do |s| 
          yield(s[attrib.to_s])
        end
      end

      def self.find_all
        a = Array.new
        connection.get(self.resource_plural_name).each do |object|
          a << self.new(object)
        end
        return a
      end

      def self.find_by_nickname(nickname)
        connection.logger("DEPRICATION WARNING: use of find_by_nickname is depricated, please use find_by(:nickname) { |n| n == '#{nickname}' } ")
        self.find_by(:nickname) { |n| n == nickname }
      end

      def reload
        uri = URI.parse(self.href)
        @params ? @params.merge!(connection.get(uri.path)) : @params = connection.get(uri.path)
      end

      # the argument can be 
      # 1) takes href (URI), 
      # 2) or id (Integer)
      # 3) or symbol :all, :first, :last
      def self.find(href, &block)
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

      def self.find_by_id(id)
        connection.logger("DEPRICATION WARNING: use of find_by_id is depricated, please use find(id) ")
        self.find(id)
      end

      def self.create(opts)
        location = connection.post(self.resource_plural_name, self.resource_singluar_name.to_sym => opts)
        newrecord = self.new('href' => location)
        newrecord.reload
        newrecord
      end

# filter is only implemented on some api endpoints
      def self.find_by_nickname_speed(nickname)
        self.find_with_filter('nickname' => nickname)
      end

# filter is only implemented on some api endpoints
      def self.find_with_filter(filter = {})
        filter_params = ""
        filter.each {|key,val| filter_params += "filter[]=#{key}=#{val}&"}
        a = Array.new
        connection.get(self.resource_plural_name, filter_params).each do |object|
          a << self.new(object)
        end
        return a
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
          @params[mn] = args[0] if assignment
          return @params[mn] 
        elsif @params[mn_dash]
          @params[mn_dash] = args[0] if assignment
          return @params[mn_dash] 
        else  
          raise "called unknown method #{method_name} with #{args.inspect}"
        end
      end

      def [](name)
        try_these = [name, name.gsub(/_/,'-'), name.to_sym]
        try_these.each do |t|
          if @params[t]
            return @params[name]
          else
            return nil
          end
        end
      end

    end
  end
end
