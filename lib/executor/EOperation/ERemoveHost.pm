# ERemoveHost.pm - Operation class implementing Host creation operation

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

use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

sub checkOp{
    my $self = shift;
    my %args = @_;
    
    # check if host is not active
    $log->debug("checking host active value <$args{params}->{host_id}>");
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

    General::checkParams(args => \%args, required => ["internal_cluster"]);

    my $params = $self->_getOperation()->getParams();

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
}

sub execute{
    my $self = shift;
    $self->SUPER::execute();
    my ($powersupplycard, $powersupplyid);

    my $powersupplycard_id = $self->{_objs}->{host}->getPowerSupplyCardId();
    if ($powersupplycard_id) {
        $powersupplycard = Entity::Powersupplycard(id => $powersupplycard_id);
        $powersupplyid = $self->{_objs}->{host}->getAttr(name => 'host_powersupply_id');
    }
    $self->{_objs}->{host}->delete();

    if ($powersupplycard_id){
        $log->debug("Deleting powersupply with id <$powersupplyid> on the card : <$powersupplycard>");
        $powersupplycard->delPowerSupply(powersupply_id => $powersupplyid);
    }
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
