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
# API 1.5
#
class MonitoringMetric
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :create, :destroy, :update

  def self.parse_args(cloud_id, instance_id)
    "clouds/#{cloud_id}/instances/#{instance_id}/"
  end

  def self.filters
    [:plugin, :view]
  end

  def data(start_time = "-60", end_time = "0")
    params = {'start' => start_time.to_s, 'end' => end_time.to_s}
    monitor = connection.get(URI.parse(self.href).path + "/data", params)
    # NOTE: The following is a dirty hack
    monitor['data'] = monitor['variables_data'].first
    monitor['data']['value'] = monitor['data']['points']
    monitor
  end
end
