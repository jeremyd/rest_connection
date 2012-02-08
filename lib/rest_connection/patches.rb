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
    unless self.class === second
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
    unless self.class === second
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
    unless self.class === second
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
    unless self.class === second
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
