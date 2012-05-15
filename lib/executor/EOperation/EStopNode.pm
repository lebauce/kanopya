# EStopNode.pm - Operation class implementing stop node operation

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

EOperation::EStopNode - Operation class implementing stop node operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement stop node operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EStopNode;
use base "EOperation";

use Kanopya::Exceptions;
use EFactory;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host" ]);
}

sub prerequisites {
    my $self  = shift;
    my %args  = @_;
    my $delay = 10;

    my $cluster_id = $self->{context}->{cluster}->getAttr(name => 'entity_id');
    my $host_id    = $self->{context}->{host}->getAttr(name => 'entity_id');

    # Ask to all cluster component if they are ready for node addition.
    my $components = $self->{context}->{cluster}->getComponents(category => "all");
    foreach my $key (keys %$components) {
        my $ready = $components->{$key}->readyNodeRemoving(host_id => $self->{context}->{host}->getAttr(name => "host_id"));
        if (not $ready) {
            $log->debug("Cluster <$cluster_id> not ready for node removing, retrying in $delay seconds");
            return $delay;
        }
    }

    $log->debug("Cluster <$cluster_id> ready for node removing, preparing StopNode.");
    return 0;
}

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    my $components = $self->{context}->{cluster}->getComponents(category => "all");
    $log->info('Processing cluster components configuration for this node');

    foreach my $i (keys %$components) {
        my $comp = EFactory::newEEntity(data => $components->{$i});
        $log->debug("component is ".ref($comp));
        $comp->stopNode(host    => $self->{context}->{host},
                        cluster => $self->{context}->{cluster} );
    }
    # finaly we halt the node
    $self->{context}->{host}->halt();

    $self->{context}->{host}->setNodeState(state => "goingout");
    $self->{context}->{host}->save();

}

sub finish {
    my $self = shift;

    $self->getWorkflow->enqueue(
        priority => 200,
        type     => 'PostStopNode',
    );
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
