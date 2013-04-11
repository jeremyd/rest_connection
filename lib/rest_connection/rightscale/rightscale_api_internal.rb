#--
# Copyright (c) 2010-2012 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

#
# API 0.1
#
module RightScale
  module Api
    module InternalConnection

      #
      # Config for API 0.1
      # Only works for legacy clusters
      #
      def connection(*opts)
        @@little_brother_connection ||= RestConnection::Connection.new(*opts)
        settings = @@little_brother_connection.settings
        settings[:common_headers]["X_API_VERSION"] = "1.0"
        settings[:api_href] = settings[:api_url]
        settings[:extension] = ".js"

        unless @@little_brother_connection.respond_to?(:refresh_cookie)
          @@little_brother_connection.instance_exec(&(RightScale::Api::BASE_COOKIE_REFRESH))
        end

        @@little_brother_connection.refresh_cookie unless @@little_brother_connection.cookie
        settings[:common_headers]["X_API_VERSION"] = "0.1"
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
