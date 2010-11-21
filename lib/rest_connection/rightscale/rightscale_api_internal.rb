module RightScale
  module Api
    module Internal
      def connection
        @@little_brother_connection ||= RestConnection::Connection.new
        settings = @@little_brother_connection.settings
        settings[:common_headers]["X_API_VERSION"] = "0.1"         
        settings[:api_href] = settings[:api_url]
        settings[:extension] = ".js"
        @@little_brother_connection
      end
    end

    module InternalExtend
      def connection
        @@little_brother_connection ||= RestConnection::Connection.new
        settings = @@little_brother_connection.settings
        settings[:common_headers]["X_API_VERSION"] = "0.1"         
        settings[:api_href] = settings[:api_url]
        settings[:extension] = ".js"
        @@little_brother_connection
      end
    end
  end
end
 
