# EAddHost.pm - Operation class implementing Host creation operation

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
package EOperation::EAddHost;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EFactory;
use Template;
use Log::Log4perl "get_logger";
use Data::Dumper;

use Entity::Host;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Kernel;
use Entity::Hostmodel;
use Entity::Processormodel;
use Entity::Powersupplycard;
use Entity::Gp;
use ERollback;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


sub checkOp {
    my $self = shift;
    my %args = @_;
    
    # check if kernel_id exist
    $log->debug("checking kernel existence with id <$args{params}->{kernel_id}>");
    eval {
        Entity::Kernel->get(id => $self->{_objs}->{host}->getAttr(name => 'kernel_id'));
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddHost->prepare : Wrong kernel_id attribute detected <".
                   $self->{_objs}->{host}->getAttr(name => 'kernel_id') .">\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # check if host_model_id exist
    $log->debug("Checking host model existence with id <" .
                $self->{_objs}->{host}->getAttr(name=>'hostmodel_id') .
                ">");
    eval {
          Entity::Hostmodel->get(id => $self->{_objs}->{host}->getAttr(name => 'hostmodel_id'));
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddHost->prepare : Wrong hostmodel_id attribute detected <".
                  $self->{_objs}->{host}->getAttr(name => 'hostmodel_id') . ">\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # check if processor_model_id exist
    $log->debug("Checking processor model existence with id <" .
                $self->{_objs}->{host}->getAttr(name=>'processormodel_id') .
                ">");
    eval {
         Entity::Processormodel->get(id => $self->{_objs}->{host}->getAttr(name => 'processormodel_id'));
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddHost->prepare : Wrong processormodel_id attribute detected <" .
                   $self->{_objs}->{host}->getAttr(name => 'processormodel_id')  . ">\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # check mac address unicity
    my $mac = $self->{_objs}->{host}->getAttr(name => 'host_mac_address');
    $log->debug("Checking unicity of mac address <$mac>");
    my $host = Entity::Host->getHost(hash => { host_mac_address => $mac });
    $log->debug(ref($host));
    
    if (defined $host){
        $errmsg = "There is already an existing host with MAC $mac";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    if (defined $self->{_objs}->{powersupplyport_number}) {
        # Check power supply
        # Search if there is a power supply defined
        if ($self->{_objs}->{powersupplycard}->isPortUsed(
                 powersupplyport_number => $self->{_objs}->{powersupplyport_number})) {
            $errmsg = "Operation::AddHost->new : This power supply port is already recorded!";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
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
    
    $log->debug("After Eoperation prepare and before get Administrator singleton");
    my $adm = Administrator->new();
    my $params = $self->_getOperation()->getParams();

    $self->{_objs} = {};
    
    # Put the MAC address in lowercase
    $params->{host_mac_address} = lc($params->{host_mac_address});
    
    # When powersupply is used, we save value in Operation to use %$params to instantiate host
    if (exists $params->{powersupplycard_id} and defined $params->{powersupplycard_id} and
        exists $params->{powersupplyport_number} and defined $params->{powersupplyport_number}) {
        $log->debug("powersupplyport_number <$params->{powersupplyport_number}> " .
                    "powersupplycard_id <$params->{powersupplycard_id}>");
        $self->{_objs}->{powersupplyport_number} = $params->{powersupplyport_number};
        eval {
            $self->{_objs}->{powersupplycard}
                = Entity::Powersupplycard->get(id => $params->{powersupplycard_id});
        };
        if($@) {
            my $err = $@;
            $errmsg = "EOperation::EAddHost->prepare : Wrong powersupplycard_id attribute " .
                      "detected <$params->{powersupplycard_id}>\n" . $err;
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
        $log->debug("Power supply card instanciated with id $params->{powersupplycard_id}");
        # We delete the host_powersupply_id entry to create properly in execute
    }

    if (defined $params->{powersupplycard_id}) { delete $params->{powersupplycard_id}; }
    if (defined $params->{powersupplyport_number}) { delete $params->{powersupplyport_number}; }

    # Instanciate new Host Entity
    eval {
        $self->{_objs}->{host} = Entity::Host->new(%$params);
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddHost->prepare : Wrong host attributes detected\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}

sub execute {
    my $self = shift;
    my $adm = Administrator->new();

    if (exists  $self->{_objs}->{powersupplycard} and
        defined $self->{_objs}->{powersupplycard} and
        exists  $self->{_objs}->{powersupplyport_number} and
        defined $self->{_objs}->{powersupplyport_number}) {

        my $powersupply_id = $self->{_objs}->{powersupplycard}->addPowerSupplyPort(
                                 powersupplyport_number => $self->{_objs}->{powersupplyport_number}
                             );

        $self->{_objs}->{host}->setAttr(name  => 'host_powersupply_id',
                                        value => $powersupply_id);
    }

    # Set initial state to down
    $self->{_objs}->{host}->setAttr(name => 'host_state',
                                    value => 'down:' . time);

    # Save the Entity in DB
    $self->{_objs}->{host}->save();

    my @group = Entity::Gp->getGroups(hash => {gp_name => 'Host'});
    $group[0]->appendEntity(entity => $self->{_objs}->{host});

    $log->info("Host <" . $self->{_objs}->{host}->getAttr(name => "host_mac_address") .
               "> is now created");
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
