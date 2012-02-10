#    This file is part of RestConnection
#
#    RestConnection is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    RestConnection is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with RestConnection.  If not, see <http://www.gnu.org/licenses/>.

require 'rest-client'
RestClient.log = ENV["REST_CONNECTION_LOG"] || "stdout"

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
