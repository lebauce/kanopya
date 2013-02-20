# Snmpd5.pm - Snmpd server component (Adminstrator side)
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
# Created 4 sept 2010

package Entity::Component::Snmpd5;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Config;
use Kanopya::Exceptions;
use Entity;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
	monitor_server_ip => { 
        label        => 'SNMP Server IP',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    snmpd_options => { 
        label        => 'SNMP agent options',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
};



sub getAttrDef { return ATTR_DEF; }

sub getConf {
    my ($self) = @_;

    my $snmpd5_conf;
    my $confindb = $self->{_dbix};
    if($confindb) {
       $snmpd5_conf = {
        snmpd5_id => $confindb->get_column('snmpd5_id'),
        monitor_server_ip => $confindb->get_column('monitor_server_ip'),
        snmpd_options => $confindb->get_column('snmpd_options')};
    } else {
        $snmpd5_conf = $self->getBaseConfiguration();
    }
    return $snmpd5_conf; 
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    my $conf = $args{conf};
    if (not $conf->{snmpd5_id}) {
        # new configuration -> create
        $self->{_dbix}->create($conf);
    } else {
        # old configuration -> update
        $self->{_dbix}->update($conf);
    }
}

=head2 getNetConf
B<Class>   : Public
B<Desc>    : This method return component network configuration in a hash ref, it's indexed by port and value is the port
B<args>    : None
B<Return>  : hash ref containing network configuration with following format : {port => protocol}
B<Comment>  : None
B<throws>  : Nothing
=cut

sub getNetConf {
    return { 161 => ['udp'] };
}

sub getBaseConfiguration {
	my $config = Kanopya::Config::get('executor');
    my $kanopya_cluster = Entity->get(id => $config->{cluster}->{executor});
    my $ip = $kanopya_cluster->getMasterNodeIp();
    return {
        monitor_server_ip => $ip,
        snmpd_options => "-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid"
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return "class { 'kanopya::snmpd': }\n";
}

1;
