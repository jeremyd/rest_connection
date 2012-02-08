module RightScale
  module Api
    module InternalConnection
      def connection(*opts)
        @@little_brother_connection ||= RestConnection::Connection.new(*opts)
        settings = @@little_brother_connection.settings
        settings[:common_headers]["X_API_VERSION"] = "0.1"
        settings[:api_href] = settings[:api_url]
        settings[:extension] = ".js"
        @@little_brother_connection
      end
    end

    module Internal
      include RightScale::Api::InternalConnection
    end

    module InternalExtend
      include RightScale::Api::InternalConnection
    end
  end
end
