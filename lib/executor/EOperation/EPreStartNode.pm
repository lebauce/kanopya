# EPreStartNode.pm - Operation class implementing Cluster creation operation

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

EEntity::Operation::EAddHost - Operation class implementing Host creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Host creation operation

=head1 DESCRIPTION

EPreStartNode allows to prepare cluster for node addition.
It takes as parameters :
- host_id : Int (Scalar) : host_id identifies host 
    which will be migrated into cluster to become a node.
- cluster_id : Int (Scalar) : cluster_id identifies cluster which will grow.

=head1 METHODS

=cut
package EOperation::EPreStartNode;
use base "EOperation";

use Kanopya::Exceptions;
use EFactory;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use Operation;
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

=head2 prepare

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "cluster", "host", "systemimage" ]);

    General::checkParams(args => $self->{params}, required => [ "node_number" ]);

    my $master_node_id = $self->{context}->{cluster}->getMasterNodeId();
    my $node_count = $self->{context}->{cluster}->getCurrentNodesCount();
    if (! $master_node_id && $node_count){
        $errmsg = "No master node when host <" . $self->{context}->{host}->getAttr(name => 'entity_id') .
                  "> migrating, pls wait...";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    #TODO  component migrate (node, exec context?)
    my $components = $self->{context}->{cluster}->getComponents(category => "all");
    $log->info('Processing cluster components configuration for this node');
    foreach my $i (keys %$components) {
        my $comp = EFactory::newEEntity(data => $components->{$i});

        $log->debug("component is ".ref($comp));
        $comp->preStartNode(host    => $self->{context}->{host},
                            cluster => $self->{context}->{cluster});
    }

    $self->{context}->{host}->becomeNode(
        inside_id      => $self->{context}->{cluster}->getAttr(name => "cluster_id"),
        master_node    => 0,
        systemimage_id => $self->{context}->{systemimage}->getAttr(name => "entity_id"),
        node_number    => $self->{params}->{node_number},
    );   

    # define a hostname
    my $hostname = $self->{context}->{cluster}->getAttr(name => 'cluster_basehostname');
    if ($self->{context}->{cluster}->getAttr(name => 'cluster_max_node') > 1) {
        $hostname .=  $self->{context}->{host}->getNodeNumber();
    }
    $self->{context}->{host}->setAttr(name  => "host_hostname",
                                      value => $hostname);
    $self->{context}->{host}->save();
    
    # create the node working directory where generated files will be
    # stored.
    my $dir = $self->{config}->{clusters}->{directory};
    $dir .= '/' . $self->{context}->{cluster}->getAttr(name => 'cluster_name');
    $dir .= '/' . $hostname;
    my $econtext = $self->getEContext();
    $econtext->execute(command => "mkdir -p $dir");

    $self->{context}->{host}->setNodeState(state => "pregoingin");
}

sub _cancel {
    my $self = shift;

    if ($self->{context}->{cluster}) {
        my $hosts = $self->{context}->{cluster}->getHosts();
        if (! scalar keys %$hosts) {
            $self->{context}->{cluster}->setState(state => 'down');
        }
    }

    if ($self->{context}->{host}) {
        $self->{context}->{host}->setAttr(name  => 'host_hostname',
                                          value => undef);
        $self->{context}->{host}->setState(state => 'down');   
    }
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
