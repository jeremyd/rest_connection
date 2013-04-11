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
class Deployment
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Taggable
  extend RightScale::Api::TaggableExtend

  def self.filters
    [:description, :nickname]
  end

  def reload
    uri = URI.parse(self.href)
    @params ? @params.merge!(connection.get(uri.path)) : @params = connection.get(uri.path)
    @params['cloud_id'] = cloud_id
    @params
  end

  def self.create(opts)
    location = connection.post(self.resource_plural_name, self.resource_singular_name.to_sym => opts)
    newrecord = self.new('href' => location)
    newrecord.reload
    newrecord
  end

  def set_inputs(hash = {})
    deploy_href = URI.parse(self.href)
    connection.put(deploy_href.path, :deployment => {:parameters => hash })
  end

  def set_input(name, value)
    deploy_href = URI.parse(self.href)
    connection.put(deploy_href.path, :deployment => {:parameters => {name => value} })
  end

  def servers_no_reload
    connection.logger("WARNING: No Servers in the Deployment!") if @params['servers'].empty?
    unless @params['servers'].reduce(true) { |bool,s| bool && s.is_a?(ServerInterface) }
      @params['servers'].map! { |s| ServerInterface.new(self.cloud_id, s, self.rs_id) }
    end
    @params['servers']
  end

  def servers
    # this populates extra information about the servers
    servers_no_reload.each do |s|
      s.reload
    end
  end

  def duplicate
    clone
  end

  def clone
    deploy_href = URI.parse(self.href)
    Deployment.new(:href => connection.post(deploy_href.path + "/duplicate"))
  end

  def destroy(wait_for_servers = nil)
    deploy_href = URI.parse(self.href)
    if wait_for_servers
      servers_no_reload.each { |s| s.wait_for_state("stopped") }
    end
    connection.delete(deploy_href.path)
  end

  def start_all
    deploy_href = URI.parse(self.href)
    connection.post(deploy_href.path + "/start_all")
  end

  def stop_all
    deploy_href = URI.parse(self.href)
    connection.post(deploy_href.path + "/stop_all")
  end
end
