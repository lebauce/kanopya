# EDeactivateMotherboard.pm - Operation class implementing Motherboard deactivation operation

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

EOperation::EDeactivateMotherboard - Operation class implementing motherboard deactivation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement motherboard deactivation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EDeactivateMotherboard;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);
use base "EOperation";
use lib qw (/workspace/mcs/Executor/Lib /workspace/mcs/Common/Lib);
use McsExceptions;

my $log = get_logger("executor");
my $errmsg;
$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = EOperation::EDeactivateMotherboard->new();

	# Operation::EDeactivateMotherboard->new creates a new DeactivateMotherboard operation.
	# RETURN : EOperation::EDeactivateMotherboard : Operation deactivate motherboard on execution side

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->debug("Class is : $class");
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

=head2 prepare

	$op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
	
	my $self = shift;
	my %args = @_;
	$self->SUPER::prepare();

	$log->info("Operation preparation");

	if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
		$errmsg = "EDeactivateMotherboard->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $adm = Administrator->new();
	my $params = $self->_getOperation()->getParams();

	#### Get instance of Motherboard Entity
	$log->info("Load motherboard instance");
	$self->{_objs}->{motherboard} = $adm->getEntity(type => "Motherboard", id => $params->{motherboard_id});
	$log->debug("get motherboard self->{_objs}->{motherboard} of type : " . ref($self->{_objs}->{motherboard}));

}

sub execute{
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	$log->debug("After EOperation exec and before new Adm");
	my $adm = Administrator->new();
	
	
	# set motherboard inactive in db
	$self->{_objs}->{motherboard}->setAttr(name => 'active', value => 0);
	$self->{_objs}->{motherboard}->save();
		
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
