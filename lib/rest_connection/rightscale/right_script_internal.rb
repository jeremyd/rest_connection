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
class RightScriptInternal
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend
  include RightScale::Api::Internal
  extend RightScale::Api::InternalExtend

  deny_methods :index, :show

  def resource_plural_name
    "right_scripts"
  end

  def resource_singular_name
    "right_script"
  end

  def self.resource_plural_name
    "right_scripts"
  end

  def self.resource_singular_name
    "right_script"
  end

  # NOTE: only RightScriptInternal.create() allows you to pass the ["script"] param.
  # Need to request that .save() allows update to "script"

  # commits a rightscript
  def commit(message)
    t = URI.parse(self.href)
    RightScript.new(:href => connection.post(t.path + "/commit", :commit_message => message))
  end

  # clones a RightScript and returns the new RightScript resource that's been created.
  def clone
    t = URI.parse(self.href)
    RightScript.new(:href => connection.post(t.path + "/clone"))
  end

  def fetch_right_script_attachments
    t = URI.parse(self.href)
    @params["attachments"] = []
    connection.get(t.path + "/right_script_attachments").each { |obj|
      obj.merge!("right_script_href" => self.href)
      @params["attachments"] << RightScriptAttachmentInternal.new(obj)
    }
    @params["attachments"]
  end

  def attachments
    @params["attachments"] ||= fetch_right_script_attachments
  end

=begin
  def upload_attachment(file) # TODO
    filedata = (File.exists?(file) ? IO.read(file) : file)
  end
=end
end
