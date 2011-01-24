# EActivateMotherboard.pm - Operation class implementing Motherboard activation operation

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

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

EOperation::EActivateMotherboard - Operation class implementing motherboard activation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement motherboard activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EActivateMotherboard;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;

use Entity::Cluster;
use Entity::Motherboard;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 new

    my $op = EOperation::EActivateMotherboard->new();

	# Operation::EActivateMotherboard->new creates a new ActivateMotherboard operation.
	# RETURN : EOperation::EActivateMotherboard : Operation activate motherboard on execution side

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

	$op->_init();
	# This private method is used to define some hash in Operation

=cut

sub _init {
	my $self = shift;
	$self->{_objs} = {};
	return;
}

sub checkOp{
    my $self = shift;
	my %args = @_;
	
    # check if motherboard is not active
    $log->debug("checking motherboard active value <$args{params}->{motherboard_id}>");
   	if($self->{_objs}->{motherboard}->getAttr(name => 'active')) {
	    	$errmsg = "EOperation::EActivateMotherboard->new : motherboard $args{params}->{motherboard_id} is already active";
	    	$log->error($errmsg);
	    	throw Kanopya::Exception::Internal(error => $errmsg);
    }

}

=head2 prepare

	$op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
	
	my $self = shift;
	my %args = @_;
	$self->SUPER::prepare();

	$log->info("Operation preparation");

	if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
		$errmsg = "EActivateMotherboard->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $params = $self->_getOperation()->getParams();
	
	# Instantiate motherboard and so check if exists
    $log->debug("checking motherboard existence with id <$params->{motherboard_id}>");
    eval {
    	$self->{_objs}->{motherboard} = Entity::Motherboard->get(id => $params->{motherboard_id});
    };
    if($@) {
    	$errmsg = "EOperation::EActivateMotherboard->new : motherboard_id $params->{motherboard_id} does not exist";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
	
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
		$errmsg = "Operation ActivateMotherboard failed an error occured :\n$error";
		$log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}

sub execute{
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	$log->debug("After EOperation exec and before new Adm");
	
	
	# set motherboard active in db
	$self->{_objs}->{motherboard}->setAttr(name => 'active', value => 1);
	$self->{_objs}->{motherboard}->save();
		
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Executor package so refers to Executor configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item Kanopya::Exception module used to throw exceptions managed by handling programs

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut
1;
