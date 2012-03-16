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

# Hash Patches

class Hash
  # Merges self with another second, recursively.
  #
  # This code was lovingly stolen from some random gem:
  # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
  #
  # Thanks to whoever made it.
  #
  # Modified to provide same functionality with Arrays

  def deep_merge(second)
    target = dup
    return target unless second
    unless Hash === second
      raise TypeError.new("can't convert #{second.class} into #{self.class}")
    end
    second.keys.each do |k|
      if second[k].is_a? Array and self[k].is_a? Array
        target[k] = target[k].deep_merge(second[k])
        next
      elsif second[k].is_a? Hash and self[k].is_a? Hash
        target[k] = target[k].deep_merge(second[k])
        next
      end
      target[k] = second[k]
    end
    target
  end

  # From: http://www.gemtacular.com/gemdocs/cerberus-0.2.2/doc/classes/Hash.html
  # File lib/cerberus/utils.rb, line 42
  # Modified to provide same functionality with Arrays

  def deep_merge!(second)
    return nil unless second
    unless Hash === second
      raise TypeError.new("can't convert #{second.class} into #{self.class}")
    end
    second.each_pair do |k,v|
      if self[k].is_a?(Array) and second[k].is_a?(Array)
        self[k].deep_merge!(second[k])
      elsif self[k].is_a?(Hash) and second[k].is_a?(Hash)
        self[k].deep_merge!(second[k])
      else
        self[k] = second[k]
      end
    end
  end
end

# Array Patches

class Array
  def deep_merge(second)
    target = dup
    return target unless second
    unless Array === second
      raise TypeError.new("can't convert #{second.class} into #{self.class}")
    end
    second.each_index do |k|
      if second[k].is_a? Array and self[k].is_a? Array
        target[k] = target[k].deep_merge(second[k])
        next
      elsif second[k].is_a? Hash and self[k].is_a? Hash
        target[k] = target[k].deep_merge(second[k])
        next
      end
      target << second[k] unless target.include?(second[k])
    end
    target
  end

  def deep_merge!(second)
    return nil unless second
    unless Array === second
      raise TypeError.new("can't convert #{second.class} into #{self.class}")
    end
    second.each_index do |k|
      if self[k].is_a?(Array) and second[k].is_a?(Array)
        self[k].deep_merge!(second[k])
      elsif self[k].is_a?(Hash) and second[k].is_a?(Hash)
        self[k].deep_merge!(second[k])
      else
        self << second[k] unless self.include?(second[k])
      end
    end
  end

  def *(second)
    if second.is_a?(Integer)
      ret = []
      second.times { |i| ret += dup }
      return ret
    elsif second.is_a?(Array)
      ret = []
      each { |x| second.each { |y| ret << [x,y].flatten } }
      return ret
    else
      raise TypeError.new("can't convert #{second.class} into Integer")
    end
  end

  def **(second)
    if second.is_a?(Integer)
      ret = dup
      (second - 1).times {
        temp = []
        ret.each { |x| each { |y| temp << [x,y].flatten } }
        ret = temp
      }
      return ret
    else
      raise TypeError.new("can't convert #{second.class} into Integer")
    end
  end
end
