# RightScale REST Connection

The rest_connection gem is a Ruby library for RightScale's API 1.0 and API 1.5.

It should be considered deprecated.
If you only use API 1.5, you should use the right_api_client gem instead: https://rubygems.org/gems/right_api_client

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

We follow semantic versioning according to http://semver.org

## Usage Instructions

You must setup ~/.rest_connection/rest_api_config.yaml or /etc/rest_connection/rest_api_config.yaml

Copy the example from GEMHOME/rest_connection/config/rest_api_config.yaml.sample and fill in your connection info.

Pro Tip: to find a GEMHOME, use gemedit

    "gem install gemedit"
    "gem edit rest_connection"

The following examples assume an interactive ruby session (irb):

    $ bundle exec irb
    ruby> require 'rubygems'; require 'rest_connection'

### Lookup and run a RightScript

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

## Troubleshooting

### Wrong ruby version

Ruby 1.8.7 or higher is required.

## Publishing

To cut a new gem and push to RubyGems:
Edit lib/rest_connection/version.rb

    "bundle exec gem build rest_connection.gemspec"
    "ls *.gem" <- verify that gem was built
    "cd /tmp"
    "bundle exec gem install /path/to/local/rest_connection-X.Y.Z.gem" <- replace X.Y.Z with your new version number
    "bundle exec gem uninstall rest_connection"
    "cd -"
    "bundle exec gem push rest_connection-X.Y.Z.gem"

Check it out: https://rubygems.org/gems/rest_connection
