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
# API 1.5
#
class McAuditEntry
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :destroy, :index

  def resource_plural_name
    "audit_entries"
  end

  def resource_singular_name
    "audit_entry"
  end

  def self.resource_plural_name
    "audit_entries"
  end

  def self.resource_singular_name
    "audit_entry"
  end

  def self.filters
    [:auditee_href, :user_email]
  end

  def self.find_all(start_date=nil, end_date=nil, limit=1000)
    start_date ||= (Time.now.utc - (60*60*24*31)).strftime(RightScale::Api::DATETIME_FMT)
    end_date ||= Time.now.utc.strftime(RightScale::Api::DATETIME_FMT)
    index(start_date, end_date, limit)
  end

  def self.find_with_filter(start_date, end_date, limit, filter)
    index(start_date, end_date, limit, filter)
  end

  def self.index(start_date, end_date, limit=1000, filter={})
    # Validate index params
    ex_fmt = "2011/06/25 00:00:00 +0000"
    regex = /^(\d{4})\/(\d{2})\/(\d{2}) (\d{2}):(\d{2}):(\d{2}) ([+-]\d{4})$/
    unless start_date =~ regex
      raise ArgumentError.new("start_date doesn't match format. e.g., #{ex_fmt}")
    end
    unless end_date =~ regex
      raise ArgumentError.new("end_date doesn't match format. e.g., #{ex_fmt}")
    end
    unless (1..1000) === limit.to_i
      raise ArgumentError.new("limit is not within the range of 1..1000")
    end
    filter_params = []
    filter.each { |key,val|
      unless self.filters.include?(key.to_sym)
        raise ArgumentError.new("#{key} is not a valid filter for resource #{self.resource_singular_name}")
      end
      filter_params << "#{key}==#{val}"
    }

    a = Array.new
    url = self.resource_plural_name
    if filter_params.empty?
      connection.get(url).each do |object|
        a << self.new(object)
      end
    else
      connection.get(url, :filter => filter_params).each do |object|
        a << self.new(object)
      end
    end

    return a
  end

  def append(detail, offset)
    uri = URI.parse(self.href)
    connection.post(uri.path + "/append", 'detail' => detail, 'offset' => offset)
  end

  def detail
    uri = URI.parse(self.href)
    res = connection.post(uri.path + "/detail")
    return res.body
  end
end
