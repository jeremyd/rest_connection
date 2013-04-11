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
class ServerTemplateInternal
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Internal
  extend RightScale::Api::InternalExtend

  deny_methods :index, :create, :show, :update, :destroy

  def resource_plural_name
    "server_templates"
  end

  def resource_singular_name
    "server_template"
  end

  def self.resource_plural_name
    "server_templates"
  end

  def self.resource_singular_name
    "server_template"
  end

  def add_multi_cloud_image(mci_href)
    t = URI.parse(self.href)
    connection.put(t.path + "/add_multi_cloud_image", :multi_cloud_image_href => mci_href)
  end

  def delete_multi_cloud_image(mci_href)
    t = URI.parse(self.href)
    connection.put(t.path + "/delete_multi_cloud_image", :multi_cloud_image_href => mci_href)
  end

  def set_default_multi_cloud_image(mci_href)
    t = URI.parse(self.href)
    connection.put(t.path + "/set_default_multi_cloud_image", :multi_cloud_image_href => mci_href)
  end

  def multi_cloud_images
    t = URI.parse(self.href)
    connection.get(t.path + "/multi_cloud_images")
  end

  # message <~String>: commit message string (required)
  def commit(message)
    t = URI.parse(self.href)
    ServerTemplate.new(:href => connection.post(t.path + "/commit", :commit_message => message))
  end

  # <~Executable> executable, an Executable object to add
  # <~String> Apply, a string designating the type of executable: "boot", "operational", "decommission".  Default is operational
  def add_executable(executable, apply="operational")
    t = URI.parse(self.href)
    params = {}
    if executable.recipe?
      params[:recipe] = executable.href
    else
      params[:right_script_href] = executable.href
    end
    params[:apply] = apply
    connection.post(t.path + "/add_executable", params)
  end

  # <~Executable> executable, an Executable object to delete
  # <~String> Apply, a string designating the type of executable: "boot", "operational", "decommission".  Default is operational
  def delete_executable(executable, apply="operational")
    t = URI.parse(self.href)
    params = {}
    if executable.recipe?
      params[:recipe] = executable.href
    else
      params[:right_script_href] = executable.href
    end
    params[:apply] = apply
    connection.delete(t.path + "/delete_executable", params)
  end

end
