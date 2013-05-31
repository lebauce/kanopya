# Mysql5.pm - Mysql 5 component module (Adminstrator side)
#    Copyright © 2011 Hedera Technology SAS
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
# Created 12 sept 2010

package Entity::Component::Mysql5;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    mysql5_port        => {
        label          => 'Port',
        type           => 'string',
        pattern        => '^\d*$',
        is_mandatory   => 1,
        is_editable    => 1
    },
    mysql5_datadir     => { 
        label          => 'Data directory',
        type           => 'string',
        pattern        => '^.*$',
        is_mandatory   => 1,
        is_editable    => 1
    },
    mysql5_bindaddress => { 
        label          => 'Bind address',
        type           => 'string',
        pattern        => '^.*$',
        is_mandatory   => 1,
        is_editable    => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getNetConf {
    my ($self) = @_;
    my $conf = {
        3306 => ['tcp'],  
    };
    return $conf;
}

sub getBaseConfiguration {
    return {
        mysql5_port => 3306,
        mysql5_datadir => "/var/lib/mysql",
        mysql5_bindaddress => '0.0.0.0'
    };
}

sub getExecToTest {
    my $self = shift;

    my $status = scalar ($self->getActiveNodes) >= 1 ? 'wsrep_connected' : 'wsrep_ready';

    return {
        mysql => {
            cmd         => 'netstat -lnpt | grep ' . $self->mysql5_port,
            answer      => '.+$',
            return_code => '0'
        },
        galera => {
            cmd         => 'mysql -u wsrep -pwsrep -e "SHOW STATUS LIKE \'' . $status . '\'" --skip-column-names | cat',
            answer      => '^' . $status . '\tON$',
            return_code => 0
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args)   = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);


    my $cluster_address = 'gcomm://';
    my @fqdns           = map { $_->fqdn } (grep { $_->node_id != $args{host}->node->node_id } $self->getActiveNodes);
    $cluster_address   .= join ',', @fqdns;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        mysql => {
            manifest => $self->instanciatePuppetResource(
                            name => "kanopya::mysql",
                            params => {
                                config_hash => {
                                    port => $self->mysql5_port,
                                    bind_address => $self->mysql5_bindaddress,
                                    datadir => $self->mysql5_datadir
                                },
                                galera => {
                                    address => $cluster_address,
                                    name => $self->service_provider->cluster_name
                                }
                            }
                        )
        }
    } );
}

1;
