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

class Ec2ServerArrayInternal
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Internal
  extend RightScale::Api::InternalExtend
  
  deny_methods :index, :show, :create, :update, :destroy

  def run_script_on_instances(script, ec2_instance_hrefs=[], opts={})
    uri = URI.parse(self.href)
    case script
    when Executable then script = script.right_script
    when String then script = RightScript.new('href' => script)
    end

    params = {:right_script_href => script.href }
    unless ec2_instance_hrefs.nil? || ec2_instance_hrefs.empty?
      params[:ec2_instance_hrefs] = ec2_instance_hrefs
    end
    unless opts.nil? || opts.empty?
      params[:parameters] = opts
    end
    params = {:ec2_server_array => params}
    status_array=[]
    connection.post(uri.path + "/run_script_on_instances", params).map do |work_unit|
      status_array.push Status.new('href' => work_unit)
    end
    return(status_array)
  end
end
