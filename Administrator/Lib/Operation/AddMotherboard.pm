# AddMotherboard.pm - Operation class implementing Motherboard creation operation

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
# Created 14 july 2010

=head1 NAME

Operation::AddMotherboard - Operation class implementing Motherboard creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Motherboard creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package Operation::AddMotherboard;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use base "Operation";
use Entity::Motherboard;
use Data::Dumper;


my $log = get_logger("administrator");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = Operation::AddMotherboard->new();

Operation::AddMotherboard->new creates a new AddMotheboard operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;

	# presence of 'params' named argument is done in parent class
    my $self = $class->SUPER::new( %args );
    my $admin = $args{administrator};
        
    Entity::Motherboard->checkAttrs(attrs => $args{params});
    
    # check if kernel_id exist
    $log->debug("checking kernel existence with id <$args{params}->{kernel_id}>");
    my $row = $admin->{db}->resultset('Kernel')->find($args{params}->{kernel_id});
    if(! defined $row) {
    	$errmsg = "Operation::AddMotherboard->new : kernel_id $args{params}->{kernel_id} does not exist";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    # check if motherboard_model_id exist
    $log->debug("checking motherboard model existence with id <$args{params}->{motherboardmodel_id}>");
    $row = $admin->{db}->resultset('Motherboardmodel')->find($args{params}->{motherboardmodel_id});
    if(! defined $row) {
    	$errmsg = "Operation::AddMotherboard->new : motherboardmodel_id $args{params}->{motherboardmodel_id} does not exist";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    # check if processor_model_id exist
    $log->debug("checking processor model existence with id <$args{params}->{processormodel_id}>");
    $row = $admin->{db}->resultset('Processormodel')->find($args{params}->{processormodel_id});
    if(! defined $row) {
    	$errmsg = "Operation::AddMotherboard->new : processormodel_id $args{params}->{processormodel_id} does not exist";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    # check mac address unicity
    $log->debug("checking unicity of mac address <$args{params}->{motherboard_mac_address}>");
    $row = $admin->{db}->resultset('Motherboard')->find($args{params}->{motherboard_mac_address});
    if(defined $row) {
    	$errmsg = "Operation::AddMotherboard->new : motherboard_mac_address $args{params}->{motherboard_mac_address} already exist";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    if (defined $args{params}->{motherboard_powersupply_id}){
    # Check power supply
    # Search if there is a power supply defined
    # TODO User will have to select the powersupplycard and after specify 
    	$row = $admin->{db}->resultset('powersupplycard')->find(1);
    	if(! $row) {
    		$errmsg = "Operation::AddMotherboard->new : There is no power supply defined in the system!";
    		$log->error($errmsg);
    		throw Mcs::Exception::Internal(error => $errmsg);
    	}
    	my $existing_psc_id = $row->powersupplies->single({powersupplyport_id=>$args{params}->{motherboard_powersupply_id}});
		if ($existing_psc_id) {
			$errmsg = "Operation::AddMotherboard->new : This power supply port is already recorded!";
    		$log->error($errmsg);
    		throw Mcs::Exception::Internal(error => $errmsg);
		}
    }
    return $self;
}

=head2 _init

	$op->_init() is a private method used to define internal parameters.

=cut

sub _init {
	my $self = shift;
	return;
}

=head2 prepare

	$op->prepare();

=cut

sub prepare {
	my $self = shift;
	my $adm = Administrator->new();
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut