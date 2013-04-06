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
class RightScript
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  deny_methods :create, :destroy, :update

  attr_accessor :internal

  def self.from_yaml(yaml)
    scripts = []
    x = YAML.load(yaml)
    x.keys.each do |script|
      scripts << self.new('href' => "right_scripts/#{script}", 'name' => x[script].ivars['name'])
    end
    scripts
  end

  def self.from_instance_info(file = "/var/spool/ec2/rs_cache/info.yml")
    scripts = []
    if File.exists?(file)
      x = YAML.load(IO.read(file))
    elsif File.exists?(File.join(File.dirname(__FILE__),'info.yml'))
      x = YAML.load(IO.read(File.join(File.dirname(__FILE__),'info.yml')))
    else
      return nil
    end
    x.keys.each do |script|
      scripts << self.new('href' => "right_scripts/#{script}", 'name' => x[script].ivars['name'])
    end
    scripts
  end

  def initialize(*args, &block)
    super(*args, &block)
    if RightScale::Api::api0_1?
      @internal = RightScriptInternal.new(*args, &block)
    end
  end
end
