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

#
# You must have Beta v1.5 API access to use these internal API calls.
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
