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
# API 1.0
#
class Ec2ServerArray
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Taggable
  extend RightScale::Api::TaggableExtend

  attr_accessor :internal

  def initialize(*args, &block)
    super(*args, &block)
  end

#  Example:
#    right_script = @server_template.executables.first
#    result = @my_array.run_script_on_all(right_script, [@server_template.href])
  def run_script_on_all(script, server_template_hrefs, inputs=nil)
     serv_href = URI.parse(self.href)
     options = Hash.new
     options[:ec2_server_array] = Hash.new
     options[:ec2_server_array][:right_script_href] = script.href
     options[:ec2_server_array][:parameters] = inputs unless inputs.nil?
     options[:ec2_server_array][:server_template_hrefs] = server_template_hrefs
# bug, this only returns work units if using xml, for json all we get is nil.  scripts still run though ..
     connection.post("#{serv_href.path}/run_script_on_all", options)
  end

  #
  # Run a script on individual instances in a ServerArray
  #
  # This was formerly located in Ec2ServerArrayInternal but has 
  # been moved here to Ec2ServerArray as the call has been ported
  # from API 0.1 to API 1.0.
  #
  # Example: array.run_script_on_instances(right_script, server_href, options_hash)
  #
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

  def instances
    serv_href = URI.parse(self.href)
    connection.get("#{serv_href.path}/instances")
    rescue
    [] # raise an error on self.href which we want, it'll just rescue on rackspace and return an empty array.
  end

  def terminate_all
    serv_href = URI.parse(self.href)
    connection.post("#{serv_href.path}/terminate_all")
  end

  def launch
    serv_href = URI.parse(self.href)
    connection.post("#{serv_href.path}/launch")
  end
end

