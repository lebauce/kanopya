# EVirtual.pm - class of virtual EHosts object

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
# Created 20 nov 2011

=head1 NAME

EVirtual - execution class of virtual host entities

=head1 SYNOPSIS



=head1 DESCRIPTION

EHost::EVirtual is the execution class for virtual host entities

=head1 METHODS

=cut
package EEntity::EHost::EVirtual;
use base "EEntity::EHost";
use Entity::Cluster;
use strict;
use warnings;
use Log::Log4perl "get_logger";
use Operation;

my $log = get_logger("executor");

sub new {
    my $class = shift;
    my %args = @_;
    
    my $evirtual_ecomp = $args{evirt_ecomp};
    my $virt_cluster = $args{virt_cluster};
    delete $args{evirt_ecomp};
    delete $args{virt_cluster};
    
    my $self = $class->SUPER::new(%args);
    
    $self->{ecomponent_virt} = $evirtual_ecomp;
    $self->{virt_cluster} = $virt_cluster;
    $log->debug("Create a Virtual Host");
    return $self;
}

sub start{
    my $self = shift;
    my %args = @_;
    
    $self->{ecomponent_virt}->startvm(cluster=>$self->{virt_cluster}, host => $self->_getEntity());
    $self->_getEntity()->setState(state => 'starting');
}

sub stop {
	my $self = shift;
    my %args = @_;
    
    $self->{ecomponent_virt}->stopvm(cluster=>$self->{virt_cluster}, host => $self->_getEntity());
    $self->_getEntity()->setAttr(name => 'active', value => 0);
    $self->_getEntity()->save;
    $self->_getEntity()->remove;
}

sub postStart {
	my $self = shift;
	$self->{ecomponent_virt}->updatevm(cluster=>$self->{virt_cluster}, host => $self->_getEntity());
}

1;
