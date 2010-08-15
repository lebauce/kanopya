# RemoveMotherboardFromCluster.pm - Operation class implementing Cluster creation operation

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

Operation::AddMotherboardInCluster - Operation class implementing Motherboard migration to a cluster

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Motherboard creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package Operation::RemoveMotherboardFromCluster;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use base "Operation";
use Entity::Cluster;
use Entity::Motherboard;

my $log = get_logger("administrator");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = Operation::AddMotherboardInCluster->new(%args);

Operation::AddMotherboardInCluster->new creates a new AddMotheboard operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    $self->_init();
 
	if ((! exists $args{params} or ! defined $args{params})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "Operation->RemoveMotherboardFromCluster need a params named argument!"); }
	if ((! exists $args{params}->{cluster_id} or ! defined $args{params}->{cluster_id}) ||
		(! exists $args{params}->{motherboard_id} or ! defined $args{params}->{motherboard_id})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "Operation->RemoveMotherboardFromCluster Need a motherboard_id and a cluster_id"); }
 #TODO Here check cluster and motherboard existance and rights


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