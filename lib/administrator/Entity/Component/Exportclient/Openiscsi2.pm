# Openiscsi2.pm -open iscsi component (iscsi client) (Adminstrator side)
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
# Created 5 august 2010
package Entity::Component::Exportclient::Openiscsi2;

use base "Entity::Component::Exportclient";
use strict;
use Template;
use String::Random;
use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");
my $errmsg;



# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub getExports {
	my $self = shift;
	my $export_rs = $self->{_dbix}->openiscsi2s;
	my @tab_exports =();
	while (my $export_row = $export_rs->next){
		my $export ={};
		$export->{target} = $export_row->get_column('openiscsi2_target');
		$export->{ip} = $export_row->get_column('openiscsi2_server');
		$export->{port} = $export_row->get_column('openiscsi2_port');
		$export->{mount_point} = $export_row->get_column('openiscsi2_mount_point');
		$export->{options} = $export_row->get_column('openiscsi2_mount_options');
		$export->{fs} = $export_row->get_column('openiscsi2_filesystem');
		push @tab_exports, $export;
	}
	$log->debug("asked openiscsi import : " . Dumper(@tab_exports));
	return \@tab_exports;
}

1;
