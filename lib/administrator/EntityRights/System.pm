# EntityRights/System.pm  

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

EntityRights::System

=head1 SYNOPSIS


=head1 DESCRIPTION

EntityRights::System provide unique method build which instanciate 
an EntityRights::User or EntityRights::System depending on
$session argument content. 

=cut

package EntityRights::System;
use base 'EntityRights';

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Kanopya::Exceptions;
use General;

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;

=head2 new

    Class : Private (use EntityRights::build method to retrieve an EntityRights::* instance)
    
    Desc : constructor method
    
    args:
        schema : AdministratorDB::Schema object : DBIx database schema
        entity_id : scalar (int) : user entity_id 
        
    return: EntityRights::System instance

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['entity_id', 'schema']);

    my $self = { 
        schema => $args{schema},
        user_entity_id => $args{entity_id},
        user_id => $args{schema}->resultset("UserEntity")->find({entity_id => $ENV{EID}}, key => "entity_id")->get_column("user_id")        
    };
    #$log->debug("User Entity ID <$ENV{EID}> and user id is <" . $args{schema}->resultset("UserEntity")->find({entity_id => $ENV{EID}}, key => "entity_id")->get_column("user_id") . ">");
    bless $self, $class;
    return $self;
}

=head2 checkPerm

    Class: Public
    
    Desc: verify permission access method 

    args: 
        method : scalar (string) : method name to check
        entity_id : scalar (int) : entity_id of entity concerned
        
    return: scalar(int) : already 1

=cut

sub checkPerm {
    return 1;
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut