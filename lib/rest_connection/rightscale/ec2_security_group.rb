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
class Ec2SecurityGroup
  include RightScale::Api::Base
  extend RightScale::Api::BaseExtend

  VALID_RULE_TYPES =  [
                        [:group, :owner],
                        [:cidr_ips, :from_port, :protocol, :to_port],
                        [:from_port, :group, :owner, :protocol, :to_port],
                      ]

  # NOTE - Create, Destroy, and Update require "security_manager" permissions
  # NOTE - Can't remove rules, can only add
  def add_rule(opts={})
    rule = {}
    opts.each { |k,v| rule["#{k}".to_sym] = v }    

    unless validate_rule(rule)
      raise ArgumentError.new("add_rule expects one of these valid rule types: #{VALID_RULE_TYPES.to_json}")
    end

    params = {:ec2_security_group => rule}
    uri = URI.parse(self.href)
    connection.put(uri.path, params)

    self.reload
  end

  def validate_rule(rule)
    VALID_RULE_TYPES.each do |valid_rule_type|
      if rule.keys.sort_by {|sym| sym.to_s} == valid_rule_type.sort_by {|sym| sym.to_s}
        return true
      end
    end

    false
  end
end
