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

require 'rest-client'
RestClient.log = ENV["REST_CONNECTION_LOG"] || "stdout"

#
# API 0.1
#
class RightScriptAttachmentInternal
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Internal
  extend RightScale::Api::InternalExtend

  deny_methods :index, :create, :update

  def resource_plural_name
    "right_script_attachments"
  end

  def resource_singular_name
    "right_script_attachment"
  end

  def self.resource_plural_name
    "right_script_attachments"
  end

  def self.resource_singular_name
    "right_script_attachment"
  end

  def self.get_s3_upload_params(right_script_href)
    url = self.resource_plural_name + "/get_s3_upload_params"
    params = {"right_script_href" => right_script_href}
    params = {self.resource_singular_name => params}
    connection.get(url, params)
  end

=begin
  def self.upload(filepath, right_script_href)
    hsh = get_s3_upload_params(right_script_href)
    params = {}
    hsh.keys.each { |k| params[k.gsub(/-/,"_").to_sym] = hsh[k] }
    params[:file] = File.new(filepath, 'rb')
    req = RestClient::Request.new({
      :method => :post,
      :url => hsh["url"],
      :payload => params,
      :multipart => true,
    })
    s = req.payload.to_s
    splitter = s.split("\r\n").first
    a = s.split(/#{splitter}-?-?\r\n/)
    a.push(a.delete(a.detect { |n| n =~ %r{name="file";} }))
    new_payload = a.join(splitter + "\r\n") + splitter + "--\r\n"

    uri = URI.parse(hsh["url"])
    net_http = Net::HTTP::Post.new(uri.request_uri)
    req.transmit(uri, net_http, new_payload)
    # TODO: Precondition Failing

    callback_uri = URI.parse(hsh["success_action_redirect"])
    connection.get(callback_uri.request_uri)
  end
=end

  def download
    self.reload unless @params["authenticated_s3_url"]
    RestClient.get(@params["authenticated_s3_url"])
  end

  def download_to_file(path=Dir.pwd)
    data = self.download
    File.open(File.join(path, @params["filename"]), 'w') { |f| f.write(data) }
  end

  def reload
    uri = URI.parse(self.href || "#{resource_plural_name}/#{@params["id"]}")
    @params ? @params.merge!(connection.get(uri.path)) : @params = connection.get(uri.path)
  end
end
