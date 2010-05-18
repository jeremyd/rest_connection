module RightScale
  module Api
    module Internal
      def connection
        @@little_brother_connection ||= RestConnection::Connection.new
        @@little_brother_connection.settings[:common_headers] = { 'X-API-VERSION' => '0.1' }
        @@little_brother_connection
      end
    end

    module InternalExtend
      def connection
        @@little_brother_connection ||= RestConnection::Connection.new
        @@little_brother_connection.settings[:common_headers] = { 'X-API-VERSION' => '0.1' }
        @@little_brother_connection
      end
    end
  end
end
 
