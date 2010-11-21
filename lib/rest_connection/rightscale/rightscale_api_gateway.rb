module RightScale
  module Api
    module Gateway
      def connection        
        @@gateway_connection ||= RestConnection::Connection.new
        settings = @@gateway_connection.settings
        settings[:common_headers]["X_API_VERSION"] = "1.5"         
        settings[:api_href], account = settings[:api_url].split(/\/acct\//) if settings[:api_url].include?("acct")
        settings[:extension] = ""
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
    end

    module GatewayExtend
      def connection        
        @@gateway_connection ||= RestConnection::Connection.new
        settings = @@gateway_connection.settings
        settings[:common_headers]["X_API_VERSION"] = "1.5"         
        settings[:api_href], account = settings[:api_url].split(/\/acct\//) if settings[:api_url].include?("acct")
        settings[:extension] = ""
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
    end
  end
end
 
