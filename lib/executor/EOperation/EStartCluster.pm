# EStartCluster.pm - Operation class implementing cluster starting operation

#    Copyright © 2010-2012 Hedera Technology SAS
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
# Created 14 july 2010

=head1 NAME

EEntity::EOperation::EStartCluster - Operation class implementing cluster starting operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster starting operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package EOperation::EStartCluster;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use base "EOperation";

use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;

my $log = get_logger("executor");
my $errmsg;

our $VERSION = "1.00";


=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => \%args, required => [ "internal_cluster" ]);

    my $params = $self->_getOperation()->getParams();

    General::checkParams(args => $params, required => [ "cluster_id" ]);

    $self->{_objs} = {};
    
    # Get cluster to start from param
    $self->{_objs}->{cluster} = Entity::ServiceProvider::Inside::Cluster->get(
                                    id => $params->{cluster_id}
                                );
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    # Just call Master node addition, other node will be add by the state manager
    $self->{_objs}->{cluster}->addNode();
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
