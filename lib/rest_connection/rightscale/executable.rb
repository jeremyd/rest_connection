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
class Executable
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  deny_methods :index, :create, :destroy, :update

  # executable can be EITHER a right_script or recipe
  # executable example params format:
  # can have recipes AND right_scripts
  # @params =
  #    { :recipe =>
  #      :position => 12,
  #      :apply => "operational",
  #      :right_script => { "href" => "http://blah",
  #                         "name" => "blah"
  #                         ...
  #      }

  def recipe?
    if self["recipe"] == nil # && right_script['href']
      return false
    end
    true
  end

  def right_script?
    if self["recipe"] == nil # && right_script['href']
      return true
    end
    false
  end

  def name
    if right_script?
      return right_script.name
    else
      return recipe
    end
  end

  def href
    if right_script?
      return right_script.href
    else
      #recipes do not have hrefs, only names
      return recipe
    end
  end

  def right_script
    RightScript.new(@params['right_script'])
  end
end
