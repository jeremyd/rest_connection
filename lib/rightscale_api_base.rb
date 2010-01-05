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

module RightScale
  module Api
    class Base
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

      def self.find_all
        a = Array.new
        connection.get(self.resource_plural_name).each do |object|
          a << self.new(object)
        end
        return a
      end

      def self.find_by_nickname(nickname)
        self.find_all.select do |s| 
          s.nickname == nickname
        end
      end

      def reload
        uri = URI.parse(self.href)
        @params = connection.get(uri.path)
      end

      def self.find(href)
        uri = URI.parse(href)
        self.new(connection.get(uri.path))
      end

      def self.find_by_id(id)
        self.new(connection.get(self.resource_plural_name + "/#{id}"))
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

      # the following two methods are used to access the @params hash in a friendly way
      def method_missing(method_name, *args)
        if @params[method_name.to_s]
          return @params[method_name.to_s] 
        elsif @params[method_name.to_s.gsub(/_/,'-')]
          return @params[method_name.to_s.gsub(/_/,'-')]
        else  
          raise "called unknown method #{method_name} with #{args.inspect}"
        end
      end

      def [](name)
        if @params[name]
          return @params[name]
        else
          return nil
        end
      end

    end
  end
end
