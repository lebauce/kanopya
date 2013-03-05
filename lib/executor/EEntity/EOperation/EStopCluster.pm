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
package EEntity::EOperation::EStopCluster;
use base "EEntity::EOperation";

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Entity::ServiceProvider::Cluster;
my $log = get_logger("");
my $errmsg;

our $VERSION = "1.00";

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "cluster" ]);
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    my @hosts = $self->{context}->{cluster}->getHosts();

    if (not scalar(@hosts)) {
        $self->{context}->{cluster}->setState(state  => 'stopping');
        $errmsg = "This cluster <" . $self->{context}->{cluster}->id . "> seems to have no node.";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    foreach my $host (@hosts) {
        # We stop nodes with state 'up' only
        # TODO: ma,ager others nodes states
        my ($state, $timestamp) = $host->getState();
        if($state ne 'up') { next; }

        $self->{context}->{cluster}->removeNode(host_id => $host->id);
    }

    $self->{context}->{cluster}->setState(state => 'stopping');
    $self->{context}->{cluster}->save();
}

1;
