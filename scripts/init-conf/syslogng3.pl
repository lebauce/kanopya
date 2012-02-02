#!/usr/bin/perl -w
#
# This script initialize configuration of syslogng3 component for Admin cluster
#

use lib </opt/kanopya/lib/*>;

use Administrator;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Component::Logger::Syslogng3;

# Initial configuration
my $conf = {
    entries => [
        { entry_type => 'source', entry_name => 's_net', params => [{ content => "udp(ip(0.0.0.0))" }] },
        { entry_type => 'destination', entry_name => 'd_by_node',
	  params => [{ content => 'file("/var/log/kanopya/$HOST-messages" template("$HOUR:$MIN:$SEC $HOST <$FACILITY.$PRIORITY> $MSG\n") template_escape(no))' }] },
        ],
    logs => [
        { log_params => [ {type =>'source', name => 's_net'}, {type =>'destination', name => 'd_by_node'}] },
    ],
};

# Authenticate
Administrator::authenticate(login => "admin", password => "admin");

# Get admin cluster
my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => 1);

# Get component instance of syslogng3
my $comp = $cluster->getComponent( category => 'Logger', name => 'Syslogng', version => 3 );

# Set configuration
$comp->setConf( $conf );

print "done\n";
