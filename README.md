# RightScale REST Connection

The rest_connection gem is a Ruby library for RightScale's API 0.1, 1.0 and 1.5.

Legacy clusters:
- API 0.1 AWS clouds
- API 1.0 AWS clouds
- API 1.5 non-AWS clouds

Unified clusters:
- API 1.0 AWS clouds
- API 1.5 all clouds

This gem also supports RightScale's instance facing API 1.0, which use the instance token to login.
The instance token is found in the instance's user data as 'RS_rn_auth' or alternatively as part of 'RS_api_url'.
The user data is available under the 'Info' tab on the server's page in the RightScale Dashboard.

This gem should be considered deprecated!

If you only use API 1.5, you should use the right_api_client gem instead:
https://rubygems.org/gems/right_api_client

- API 1.0 Documentation: http://support.rightscale.com/12-Guides/03-RightScale_API
- API 1.0 Reference Docs: http://reference.rightscale.com/api1.0
- API 1.5 Documentation: http://support.rightscale.com/12-Guides/RightScale_API_1.5
- API 1.5 Reference Docs: http://reference.rightscale.com/api1.5

Maintained by the RightScale "Yellow_team" 

## Installation

Ruby 1.8.7 or higher is required.

### Installing from RubyGems

    "gem install rest_connection"

### Installing from source

    "git clone git@github.com:rightscale/rest_connection.git"
    "cd rest_connection"
    "gem install rconf"
    "rconf" <- follow any further instructions from rconf
    "bundle install"

## Versioning

This gem follows semantic versioning: http://semver.org

## Usage Instructions

You must setup '~/.rest_connection/rest_api_config.yaml' or '/etc/rest_connection/rest_api_config.yaml'

Copy the example from '$GEMHOME/rest_connection/config/rest_api_config.yaml.sample' and fill in your connection info.

Pro Tip: to find a $GEMHOME, use gemedit

    "gem install gemedit"
    "gem edit rest_connection"

The following examples assume an interactive ruby session (irb):

    $ bundle exec irb
    ruby> require 'rubygems'; require 'rest_connection'

### Look up and run a RightScript

    first_fe = Server.find(:first) { |s| s.nickname =~ /Front End/ }
    st = ServerTemplate.find(first_fe.server_template_href)
    connect_script = st.executables.detect { |ex| ex.name =~ /LB [app|mongrels]+ to HA proxy connect/i }
    state = first_fe.run_executable(connect_script)
    state.wait_for_completed

### Stop a Deployment

    deployment = Deployment.find(opts[:id])
    my_servers = deployment.servers
    my_servers.each { |s| s.stop }
    my_servers.each { |s| s.wait_for_state("stopped") }

### Activate an Ec2ServerArray / Display instances IPs

    my_array = Ec2ServerArray.find(opts[:href])
    my_array.active = true
    my_array.save

    puts my_array.instances.map { |i| i['ip-address'] }

## Design Decisions

Currently, all API resources are represented by classes in 'lib/rest_connection/rightscale'.
Various helper modules are also located in this directory.

### API 0.1 resources

API 0.1 resources are often named with suffix '_internal'.

They often pull in common internal code:

    include RightScale::Api::Internal
    extend RightScale::Api::InternalExtend

### API 1.0 resources

API 1.0 resources are often named with prefix 'ec2_' for Amazon Elastic Compute Cloud.

They often pull in common internal code:

    include RightScale::Api::Base
    extend RightScale::Api::BaseExtend

### API 1.5 resources

API 1.5 resources are often named with prefix 'mc_' for MultiCloud.
They often talk to the MultiCloud gateway and therefore pull in some common gateway code:

    include RightScale::Api::Gateway
    extend RightScale::Api::GatewayExtend

## Troubleshooting

### Wrong ruby version

Ruby 1.8.7 or higher is required.

## Publishing

To cut a new gem and push to RubyGems:

Edit lib/rest_connection/version.rb with semantic version number.

    "bundle exec gem build rest_connection.gemspec"
    "ls *.gem" <- verify that gem was built
    "cd /tmp"
    "bundle exec gem install /path/to/local/rest_connection-X.Y.Z.gem" <- replace X.Y.Z with your new version number
    "bundle exec gem uninstall rest_connection"
    "cd -"
    "bundle exec gem push rest_connection-X.Y.Z.gem"

Check it out: https://rubygems.org/gems/rest_connection
