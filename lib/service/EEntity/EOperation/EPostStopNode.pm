#    Copyright © 2009-2013 Hedera Technology SAS
#
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

=pod
=begin classdoc

Prepare the node removal. Select a node to remove if not defined,

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EPostStopNode;
use base EEntity::EOperation;

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Systemimage;
use EEntity;

use TryCatch;
use String::Random;
use Log::Log4perl "get_logger";

my $log = get_logger("");



=pod
=begin classdoc

@param cluster the cluster on which remove a node
@param host    the host corresponding to the node to remove

=end classdoc
=cut

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => $self->{context}, required => [ "cluster", "host" ]);
}


=pod
=begin classdoc

Configure the cluster component due to the node removal, release user quotas,
remove the system image if the cluster is non persistent.

=end classdoc
=cut

sub execute {
    my $self = shift;

    # Update the user quota on ram and cpu
    $self->{context}->{cluster}->owner->releaseQuota(
        resource => 'ram',
        amount   => $self->{context}->{host}->host_ram,
    );
    $self->{context}->{cluster}->owner->releaseQuota(
        resource => 'cpu',
        amount   => $self->{context}->{host}->host_core,
    );

    $log->info('Processing cluster components configuration for this node');
    $self->{context}->{cluster}->postStopNode(host => $self->{context}->{host});

    my $image;
    my $systemimage_name;
    # Handle the remaning system image of the node
    try {
        # NOTE: Can not use the relation node->systemimage any more
        # TODO: Keep the id of the system image to get it from deployment manager
        $systemimage_name = $self->{context}->{cluster}->cluster_name . '_' .
                            $self->{context}->{host}->node->node_number;

        $image = EEntity->new(data => Entity::Systemimage->find(hash => {
                     systemimage_name => $systemimage_name
                 }));
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        $log->warn("Can not find a systemimage labeled $systemimage_name for node "
                   . $self->{context}->{host}->label );
    }

    if (defined $image) {
        try {
            # Delete the image if persistent policy not set
            if ($self->{context}->{cluster}->cluster_si_persistent eq '0') {
                $image->remove(erollback => $self->{erollback});

            } else {
                $log->info("Cluster image persistence is set, keeping image "
                           . $image->label);
            }
        }
        catch (Kanopya::Exception::Execution $err) {
            $log->warn("Unable to remove system image for node "
                       . $self->{context}->{host}->label);
            $log->error("$err");
        }
    }

    $log->info('Unregister the node');
    $self->{context}->{cluster}->unregisterNode(node => $self->{context}->{host}->node);
}


=pod
=begin classdoc

Release the host here, because some host manager enqueue a RemoveHost operation.

=end classdoc
=cut

sub postrequisites {
    my ($self, %args) = @_;

    # Release the host
    $self->{context}->{host}->release();
    return 0;
}


=pod
=begin classdoc

Set the cluster as up.

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;

    # If the cluster has no node any more, it has been properly stopped
    my @nodes = $self->{context}->{cluster}->nodes;
    if (scalar (@nodes)) {
        $self->{context}->{cluster}->restoreState();
    }
    else {
        $self->{context}->{cluster}->setState(state => "down");
        if (defined $self->{context}->{host_manager_sp}) {
            $self->{context}->{host_manager_sp}->setState(state => 'up');
        }
    }

    if (defined $self->{context}->{host_manager_sp}) {
        $self->{context}->{host_manager_sp}->setState(state => 'up');
        delete $self->{context}->{host_manager_sp};
    }
}


1;
