# EAddMotherboard.pm - Operation class implementing Motherboard creation operation

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

EEntity::Operation::EAddMotherboard - Operation class implementing Motherboard creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Motherboard creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EAddMotherboard;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);
use base "EOperation";
use lib qw(.. ../../../Common/Lib);
use McsExceptions;

my $log = get_logger("executor");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = EEntity::EOperation::EAddMotherboard->new();

EEntity::Operation::EAddMotherboard->new creates a new AddMotheboard operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->warn("Class is : $class");
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
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
	$self->SUPER::prepare();

	$log->warn("After Eoperation prepare and before get Administrator singleton");
	my $adm = Administrator->new();
	my $params = $self->_getOperation()->getParams();

	$log->warn("After administator instanciation, before newObj");
	$self->{_objs} = {};

	# Get Storage Cluster
	$log->warn("adm->getObj of Cluster with id : $params->{c_storage_id}");
	my $c_cstorage = $adm->getEntity(type => "Cluster", id => $params->{c_storage_id});
	# Delete c_storage_id to have a ref on hash with motherboard parms
	delete($params->{c_storage_id});

	# Instanciate new Motherboard Entity
	$log->warn("adm->newObj of Motherboard");
	$self->{_objs}->{motherboard} = $adm->newEntity(type => "Motherboard", params => $params);
	$log->warn("New motherboard $self->{_objs}->{motherboard} of type : " . ref($self->{_objs}->{motherboard}));
	
	# Instanciate Cluster Storage component.
	$c_cstorage->getComponents(category=>"storage", administrator => $adm);
#	print Dumper $self->{_objs}->{motherboard};
}



__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut