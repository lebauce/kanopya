#    Copyright © 2011-2012 Hedera Technology SAS
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

=head1 NAME

EEntity::Operation::EAddHost - Operation class implementing Host creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Host creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::ERemoveHost;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;

use Entity::ServiceProvider;
use Entity::Host;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

sub checkOp{
    my $self = shift;
    my %args = @_;
    
    # check if host is not active
    if($self->{_objs}->{host}->getAttr(name => 'active')) {
        $errmsg = "EOperation::ERemoveHost->prepare : host $args{params}->{host_id} is still active";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => \%args, required => [ "internal_cluster" ]);

    my $params = $self->_getOperation()->getParams();

    General::checkParams(args => $params, required => [ "host_id" ]);

    $self->{_objs} = {};
    $self->{executor} = {};

    # Instantiate host and so check if exists
    $log->debug("checking host existence with id <$params->{host_id}>");
    eval {
        $self->{_objs}->{host} = Entity::Host->get(id => $params->{host_id});
    };
    if($@) {
        $errmsg = "EOperation::ERemoveHost->prepare : host_id $params->{host_id} not found";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "EOperation::ERemoveHost->checkOp failed :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    eval {
        $self->{_objs}->{ehost_manager} = EFactory::newEEntity(
                                              data => $self->{_objs}->{host}->getHostManager
                                          );
    };
    if($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{executor});
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                                          ip_destination => $exec_cluster->getMasterNodeIp());
}

sub execute{
    my $self = shift;

    $self->{_objs}->{ehost_manager}->removeHost(host      => $self->{_objs}->{host},
                                                erollback => $self->{erollback},
                                                econtext  => $self->{executor}->{econtext});
}

__END__

=head1 AUTHOR

Copyright (c) 2010-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
