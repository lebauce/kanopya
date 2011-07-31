# EPreStopNode.pm - Operation class implementing Cluster creation operation

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

EEntity::Operation::EPreStopNode - Operation class implementing Motherboard creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Motherboard creation operation

=head1 DESCRIPTION

EPreStopNode allows to prepare cluster for node addition.
It takes as parameters :
- motherboard_id : Int (Scalar) : motherboard_id identifies motherboard 
    which will be migrated into cluster to become a node.
- cluster_id : Int (Scalar) : cluster_id identifies cluster which will grow.

=head1 METHODS

=cut
package EOperation::EPreStopNode;
use base "EOperation";

use Kanopya::Exceptions;
use EFactory;
use Entity::Cluster;
use Entity::Motherboard;

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');
use Template;

my $log = get_logger("executor");
my $errmsg;

my $config = {
    INCLUDE_PATH => '/templates/internal/',
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 0,               # cleanup whitespace 
    EVAL_PERL    => 1,               # evaluate Perl code blocks
    RELATIVE => 1,                   # desactive par defaut
};


=head2 new

    my $op = EOperation::EPreStopNode->new();

    # Operation::EAddMotherboard->new creates a new AddMotheboard operation.
    # RETURN : EOperation::EAddMotherboard : Operation add motherboar on execution side

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
    $self->{nas} = {};
    $self->{executor} = {};
    $self->{bootserver} = {};
    $self->{monitor} = {};
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

    $log->info("EPreStopNode Operation preparation");

    if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
        $errmsg = "EPreStopNode->prepare need an internal_cluster named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    my $params = $self->_getOperation()->getParams();

    
    #### Get instance of Cluster Entity
    $log->info("Load cluster instance");
    $self->{_objs}->{cluster} = Entity::Cluster->get(id => $params->{cluster_id});
    $log->debug("get cluster self->{_objs}->{cluster} of type : " . ref($self->{_objs}->{cluster}));

    #### Get cluster components Entities
    $log->info("Load cluster component instances");
    $self->{_objs}->{components}= $self->{_objs}->{cluster}->getComponents(category => "all");
    $log->debug("Load all component from cluster");

    # Get instance of Motherboard Entity
    $log->info("Load Motherboard instance");
    $self->{_objs}->{motherboard} = Entity::Motherboard->get(id => $params->{motherboard_id});
    $log->debug("get Motherboard self->{_objs}->{motherboard} of type : " . ref($self->{_objs}->{motherboard}));

    my $master_node_id = $self->{_objs}->{cluster}->getMasterNodeId();
    my $node_count = $self->{_objs}->{cluster}->getCurrentNodesCount();
    if ($node_count > 1 && $master_node_id == $params->{motherboard_id}){
        $errmsg = "Node <$params->{motherboard_id}> is master node and not alone";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg, hidden=>1);
    }
}

sub execute {
    my $self = shift;
    $log->debug("Before EOperation exec");
    $self->SUPER::execute();
    $log->debug("After EOperation exec and before new Adm");
    my $adm = Administrator->new();
    

    my $components = $self->{_objs}->{components};
    $log->info('Processing cluster components configuration for this node');
    $self->{cluster_need_wait} = 0;
    foreach my $i (keys %$components) {        
        my $tmp = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is ".ref($tmp));
        $tmp->preStopNode(motherboard => $self->{_objs}->{motherboard}, 
                            cluster => $self->{_objs}->{cluster});
    }
    $self->{_objs}->{motherboard}->setNodeState(state=>"pregoingout");
}


1;
__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
