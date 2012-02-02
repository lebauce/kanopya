# EStopCluster.pm - Operation class cluster stop operation

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
# Created 14 july 2010

=head1 NAME

EOperation::EStopCluster - Operation class implementing cluster stopping operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster stopping operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package EOperation::EStopCluster;
use base "EOperation";

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Entity::ServiceProvider::Inside::Cluster;
my $log = get_logger("executor");
my $errmsg;

our $VERSION = "1.00";

=head2 new

    my $op = EOperation::EStopCluster->new();

EOperation::EStartCluster->new creates a new EStopCluster operation.

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
    
    # Get cluster to start from param
    $self->{_objs}->{cluster} = Entity::ServiceProvider::Inside::Cluster->get(id => $params->{cluster_id});
        
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();
    my $adm = Administrator->new();
    
    $log->info("getting cluster's nodes");
    my $hosts = $self->{_objs}->{cluster}->getHosts();
#    my $nodes = $adm->{manager}->{node}->getNodes(cluster_id => $self->{_objs}->{cluster}->getAttr(name => 'cluster_id'));    
    
    if(not scalar keys %$hosts) {
        $self->{_objs}->{cluster}->setState(state  => 'stopping');
        $errmsg = "EStopCluster->execute : this cluster with id $self->{_objs}->{cluster}->getAttr(name => 'cluster_id') seems to have no node";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $master_node_id =  $self->{_objs}->{cluster}->getMasterNodeId();
    my $priority = $self->_getOperation()->getAttr(attr_name => 'priority');
    
    foreach my $mb_id (keys %$hosts) {
        if ($master_node_id == $mb_id){
            next;
        }
        # we stop only nodes with 'up' state 
        #TODO gerer les nodes dans un autre état
        my ($state, $timestamp) = $hosts->{$mb_id}->getState();
        if($state ne 'up') { next; }
        $self->{_objs}->{cluster}->removeNode(host_id => $mb_id);
    }
#   $self->{_objs}->{cluster}->removeNode(host_id => $master_node_id);
    
    $self->{_objs}->{cluster}->setState(state => 'stopping');
    $self->{_objs}->{cluster}->save();
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
