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
package EEntity::EComponent::ESnmpd5;
use base 'EEntity::EComponent';

use strict;
use warnings;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

sub generateConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'cluster', 'host' ]);

    my $conf = $self->getConf();

    $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/default/snmpd',
        template_dir  => 'components/snmpd',
        template_file => 'default_snmpd.tt',
        data          => {
                             node_ip_address => $args{host}->adminIp,
                             options         => $conf->{snmpd_options}
                         }
    );

    $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/snmp/snmpd.conf',
        template_dir  => 'components/snmpd',
        template_file => 'snmpd.conf.tt',
        data          => $conf
    );
}

1;