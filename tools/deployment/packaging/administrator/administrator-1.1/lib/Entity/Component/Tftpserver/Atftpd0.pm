# Atftpd0.pm atftp (trivial ftp, part of pxe) component (Adminstrator side)
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
# Created 24 july 2010
package Entity::Component::Tftpserver::Atftpd0;

use strict;

use base "Entity::Component::Tftpserver";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getConf{
	my $self = shift;
	my $conf_raw = $self->{_dbix}->atftpd0s->first();
	return {options => $conf_raw->get_column('atftpd0_options'),
			   repository => $conf_raw->get_column('atftpd0_repository'),
			   use_inetd => $conf_raw->get_column('atftpd0_use_inetd'),
			   logfile => $conf_raw->get_column('atftpd0_logfile')};

}
1;
