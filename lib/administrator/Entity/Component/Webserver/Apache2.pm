# Apache2.pm Apache 2 web server component (Adminstrator side)
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
package Entity::Component::Webserver::Apache2;
use base "Entity::Component::Webserver";
use strict;
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
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

sub setGeneralConf {
	
}
sub addVirtualhost {
	
}

sub getVirtualhostConf{
	my $self = shift;

	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Distribution->getDevices must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	my $virtualhost_rs = $self->{_dbix}->apache2s->first->apache2_virtualhosts;
	my @tab_virtualhosts = ();
	while (my $virtualhost_row = $virtualhost_rs->next){
		my %virtualhost = $virtualhost_row->get_columns();
		push @tab_virtualhosts, \%virtualhost;
	}
	return \@tab_virtualhosts;
}

sub getGeneralConf{
	my $self = shift;

	if(! $self->{_dbix}->in_storage) {
		$errmsg = "Entity::Distribution->getDevices must be called on an already save instance";
		$log->error($errmsg);
		throw Mcs::Exception(error => $errmsg);
	}
	my %apache2_conf = $self->{_dbix}->apache2s->first->get_columns();
	$log->debug("Apache2 conf return is : " . Dumper(%apache2_conf));
	return \%apache2_conf;
}
1;
