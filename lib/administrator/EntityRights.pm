# EntityRights.pm  

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Hedera Technology sas.

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
# Created 16 july 2010

=head1 NAME

EntityRights

=head1 SYNOPSIS


=head1 DESCRIPTION

EntityRights provide unique method build which instanciate 
an EntityRights::User or EntityRights::System depending on
$session argument content. 

=cut

package EntityRights;

use strict;
use warnings;

use McsExceptions;
use EntityRights::User;
use EntityRights::System;
use Log::Log4perl "get_logger";

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;

=head2 EntityRights::build (%args)

	desc : instanciate an EntityRights::User/System depending on 
			type argument content.
	args : dbixuser : user entity DBIx::Class::Row 
		   schema : AdministratorDB::Schema instance
	return : EntityRights::User or EntityRights::System
	
=cut

sub build {
	my %args =  @_;
#	if(not exists $args{entity_id} or not defined $args{entity_id}) {
#		$errmsg = "EntityRights::build need a entity_id named argument";
#		$log->error($errmsg);
#		throw Mcs::Exception::Internal(error => $errmsg);
#	}
	
	if(not exists $args{schema} or not defined $args{schema}) {
		$errmsg = "EntityRights::build need a schema named argument";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	
	my $user = $args{schema}->resultset('User')->search({ 'user_entities.entity_id' => $ENV{EID}},
		 { join => ['user_entities'] }
	)->single;
	
	if($user->get_column('user_system')) {
		$log->debug("EntityRights build a new EntityRights::System with EID ".$ENV{EID});
		return EntityRights::System->new(entity_id => $ENV{EID}, schema => $args{schema});
	} else {
		$log->debug("EntityRights build a new EntityRights::User with EID ".$ENV{EID});
		return EntityRights::User->new(entity_id => $ENV{EID}, schema => $args{schema});
	}
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut