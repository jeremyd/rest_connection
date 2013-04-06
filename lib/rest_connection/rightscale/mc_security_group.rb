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
class McSecurityGroup
  include RightScale::Api::Gateway
  extend RightScale::Api::GatewayExtend

  deny_methods :update

  def resource_plural_name
    "security_groups"
  end

  def resource_singular_name
    "security_group"
  end

  def self.resource_plural_name
    "security_groups"
  end

  def self.resource_singular_name
    "security_group"
  end

  def self.parse_args(cloud_id)
    "clouds/#{cloud_id}/"
  end

  def self.filters
    [:name, :resource_uid]
  end

  # NOTE: Create & Destroy require "security_manager" permissions
  def self.create(cloud_id, opts={})
    url = "#{parse_args(cloud_id)}#{self.resource_plural_name}"
    location = connection.post(url, self.resource_singular_name.to_sym => opts)
    newrecord = self.new('links' => [ {'rel' => 'self', 'href' => location } ])

    rules = opts[:rules] || opts["rules"]
    [rules].flatten.each { |rule_hash| newrecord.add_rule(rule_hash) } if rules

    newrecord.reload
    newrecord
  end

  def rules
    self.load(SecurityGroupRule)
  end

  def add_rule(opts={})
    opts.each { |k,v| opts["#{k}".to_sym] = v }
    fields = [
      {"1.0" => :owner,     "1.5" => :group_owner},         # optional
      {"1.0" => :group,     "1.5" => :group_name},          # optional
      {"1.0" => :cidr_ip,   "1.5" => :cidr_ips},            # optional
      {"1.0" => :protocol,  "1.5" => :protocol},            # "tcp" || "udp" || "icmp"
      {"1.0" => :from_port, "1.5" => :start_port},          # optional
      {"1.0" => :to_port,   "1.5" => :end_port},            # optional
      {                     "1.5" => :source_type},         # "cidr_ips" || "group"
      {                     "1.5" => :icmp_code},           # optional
      {                     "1.5" => :icmp_type},           # optional
      {                     "1.5" => :security_group_href}, # optional
    ]
    unless opts[:protocol]
      raise ArgumentError.new("add_rule requires the 'protocol' option")
    end
    params = {
      :source_type => ((opts[:cidr_ip] || opts[:cidr_ips]) ? "cidr_ips" : "group"),
      :security_group_href => self.href,
      :protocol_details => {}
    }

    fields.each { |ver|
      next unless val = opts[ver["1.0"]] || opts[ver["1.5"]]
      if ver["1.5"].to_s =~ /port|icmp/
        params[:protocol_details][ver["1.5"]] = val
      else
        params[ver["1.5"]] = val
      end
    }

    SecurityGroupRule.create(params)
  end

  def remove_rules_by_filters(filters={})
    rules_to_delete = rules
    filters.each do |filter,regex|
      @rules.reject! { |rule| rule[filter] =~ Regexp.new(regex) }
    end
    @rules.each { |rule| rule.destroy }
  end
end
