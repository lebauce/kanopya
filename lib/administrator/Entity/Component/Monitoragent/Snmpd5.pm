# Snmpd5.pm - Snmpd server component (Adminstrator side)
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 4 sept 2010
package Entity::Component::Monitoragent::Snmpd5;

use strict;

use base "Entity::Component::Monitoragent";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getConf {
	my $self = shift;
	my $snmpd5_conf = {
		snmpd5_id => undef,
		monitor_server_ip => "10.0.0.1",
		snmpd_options => "-Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid"
	};
	
	my $confindb = $self->{_dbix}->snmpd5s->first();
	if($confindb) {
		snmpd5_id => $confindb->get_column('snmpd5_id'),
		monitor_server_ip => $confindb->get_column('monitor_server_ip'),
		snmpd_options => $confindb->get_column('snmpd_options'),
	}
	
	return $snmpd5_conf; 
}

sub setConf {
		my $self = shift;
	my ($conf) = @_;
		
	if(not $conf->{snmpd5_id}) {
		# new configuration -> create
		$self->{_dbix}->snmpd5s->create($conf);
	} else {
		# old configuration -> update
		$self->{_dbix}->snmpd5s->update($conf);
	}
}

1;