# rest_connection Quick Start

Maintained by the RightScale "Yellow_team" 

## Install

#### Installing with rubygems

    "gem install rest_connection"

#### Installing from source

    "git clone git@github.com:rightscale/rest_connection.git"
    "cd rest_connection"
    "gem install rconf"
    "rconf" <- follow any further instructions from rconf
    "bundle install"

## Configuration

You must setup ~/.rest_connection/rest_api_config.yaml or /etc/rest_connection/rest_api_config.yaml

Copy the example from GEMHOME/rest_connection/config/rest_api_config.yaml.sample and fill in your connection info.

Pro Tip: to find a GEMHOME, use gemedit

    "gem install gemedit"
    "gem edit rest_connection"

## Usage: some IRB samples for the RightScale API module

    $ irb
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

### To cut a new gem and push to RubyGems.org

Edit lib/rest_connection/version.rb and bump the number according to http://semver.org

    "bundle exec gem build rest_connection.gemspec"
    "ls *.gem" <- verify that gem was built
    "cd /tmp"
    "bundle exec gem install /path/to/local/rest_connection-X.Y.Z.gem" <- replace X.Y.Z with your new version number
    "bundle exec gem uninstall rest_connection"
    "cd -"
    "bundle exec gem push rest_connection-X.Y.Z.gem"

Check it out: https://rubygems.org/gems/rest_connection
