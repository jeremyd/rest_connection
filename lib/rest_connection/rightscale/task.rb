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
class Task
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :index, :create, :destroy, :update

  def self.parse_args(cloud_id, instance_id)
    "clouds/#{cloud_id}/instances/#{instance_id}/live/"
  end

  def show
    url = URI.parse(self.href)
    @params.merge! connection.get(url.path)#, 'view' => "extended")
  end

  def wait_for_state(state, timeout=900)
    while(timeout > 0)
      show
      return true if self.summary.include?(state)
      connection.logger("state is #{self.summary}, waiting for #{state}")
      raise "FATAL error:\n\n #{self.summary} \n\n" if self.summary.include?('failed') # TODO #{self.detail}
      sleep 30
      timeout -= 30
    end
    raise "FATAL: Timeout waiting for Executable to complete.  State was #{self.summary}" if timeout <= 0
  end

  def wait_for_completed(timeout=900)
    wait_for_state("completed", timeout)
  end
end
