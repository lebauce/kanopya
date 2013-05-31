#    Copyright © 2011 Hedera Technology SAS
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Entity::Component::Apache2;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Data::Dumper;
use Entity::Component::Apache2::Apache2Virtualhost;

use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    apache2_loglevel => { 
        label        => 'Log level',
        type         => 'enum',
        options      => ['debug','info','notice','warn','error','crit',
                         'alert','emerg'], 
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    apache2_serverroot => { 
        label        => 'Server root',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    apache2_ports => { 
        label        => 'HTTP Port',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    apache2_sslports => { 
        label        => 'SSL Port',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1
    },
    apache2_virtualhosts => {
        label       => 'Virtual hosts',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getBaseConfiguration {
    return {
        apache2_loglevel   => 'debug',
        apache2_serverroot => '/srv',
        apache2_ports      => 80,
        apache2_sslports   => 443,
    };
}

sub insertDefaultExtendedConfiguration {
    my $self = shift;

    Entity::Component::Apache2::Apache2Virtualhost->new(
        apache2_id                       => $self->id,
        apache2_virtualhost_servername   => 'www.yourservername.com',
        apache2_virtualhost_sslenable    => 'no',
        apache2_virtualhost_serveradmin  => 'admin@mycluster.com',
        apache2_virtualhost_documentroot => '/srv',
        apache2_virtualhost_log          => '/tmp/apache_access.log',
        apache2_virtualhost_errorlog     => '/tmp/apache_error.log',
    );
}

sub getNetConf {
    my $self = shift;

    my $http_port = $self->apache2_ports;
    my $https_port = $self->apache2_sslports;

    my %net_conf = ($http_port => ['tcp']);

    # manage ssl
    my @virtualhosts = $self->apache2_virtualhosts;
    my $ssl_enable = grep { $_->{apache2_virtualhost_sslenable} == 1 } @virtualhosts;
    $net_conf{$https_port} = ['tcp', 'ssl'] if ($ssl_enable);

    return \%net_conf;
}

sub getClusterizationType {
    return 'loadbalanced';
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    my $definitions = "class { 'kanopya::apache': }\n";

    for my $vhost ($self->apache2_virtualhosts) {
        $definitions .= "apache::vhost {\n";
        $definitions .= "\t'" . $vhost->apache2_virtualhost_servername . "':\n";
        $definitions .= "\t\tvhost_name => '" . $vhost->apache2_virtualhost_servername . "',\n";
        $definitions .= "\t\tdocroot => '" . $vhost->apache2_virtualhost_documentroot . "',\n";
        $definitions .= "\t\tserveradmin => '" . $vhost->apache2_virtualhost_serveradmin . "',\n";
        $definitions .= "\t\tlogroot => '" . $vhost->apache2_virtualhost_log . "',\n";
        $definitions .= "\t\tport => '*',\n";
        $definitions .= "}\n";
    }

    return {
        manifest     => $definitions,
        dependencies => []
    };
}

1;
