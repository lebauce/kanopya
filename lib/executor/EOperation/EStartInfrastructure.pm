#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 12 october 2011

=head1 NAME

EEntity::EOperation::EStartInfrastructure - Operation class implementing Infrastructure starting operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to start an infrastructure by starting all related clusters

=head1 DESCRIPTION



=head1 METHODS

=cut

package EOperation::EStartInfrastructure;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use base "EOperation";

use Kanopya::Exceptions;
use Entity::Infrastructure;
use Entity::Motherboard;

my $log = get_logger("executor");
my $errmsg;

our $VERSION = "1.00";

=head2 new

    my $op = EOperation::EStartInfrastructure->new();

EOperation::EStartInfrastructure->new creates a new EStartInfrastructure operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
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
    my %args = @_;
    $self->SUPER::prepare();

    my $adm = Administrator->new();
    my $params = $self->_getOperation()->getParams();

    $self->{_objs} = {};
    
    # Get infrastructure to start from param
    my $infra = Entity::Infrastructure->get(id => $params->{infrastructure_id});
    
    # Get clusters to start from infra
    #$self->{_objs}->{cluster} = Entity::Cluster->get(id => $params->{cluster_id});
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();
    my $adm = Administrator->new();
        
    # Just call Master node addition, other node will be add by the state manager
    $self->{_objs}->{cluster}->addNode();
    $self->{_objs}->{cluster}->setState(state => 'starting');
    $self->{_objs}->{cluster}->save();
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut