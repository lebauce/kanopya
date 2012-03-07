# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Entity::Component::Physicalhoster0;
use base "Entity::Component";

use strict;
use warnings;

use Entity::Powersupplycard;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;
use IO::Socket;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub getConf {
    my $self = shift;
    my $conf = {};

    return $conf;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;
}

=head2 createHost

    Desc : Implement createHost from HostManager interface.
           This function enqueue a EAddHost operation.
    args :

=cut

sub createHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "processormodel_id", "host_core", "kernel_id",
                                       "hostmodel_id", "host_mac_address",
                                       "host_serial_number", "host_ram" ]);

    $log->debug("New Operation AddHost with attrs : " . Dumper(%args));
    Operation->enqueue(
        priority => 200,
        type     => 'AddHost',
        params   => {
            host_provider_id => $self->getAttr(name => 'inside_id'),
            host_manager_id  => $self->getAttr(name => 'component_id'),
            %args
        }
    );
}

sub removeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args  => \%args, required => [ "host" ]);

    $log->debug("New Operation RemoveHost with host_id : <" .
                $args{host}->getAttr(name => "host_id") . ">");

    Operation->enqueue(
        priority => 200,
        type     => 'RemoveHost',
        params   => {
            host_id => $args{host}->getAttr(name => "host_id")
        },
    );
}

=head2 addHost

=cut

sub addHost {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "processormodel_id", "host_core", "kernel_id",
                                       "hostmodel_id", "host_mac_address",
                                       "host_serial_number", "host_ram" ]);

    # Instanciate new Host Entity
    my $host;
    eval {
        $host = Entity::Host->new(
                    service_provider_id => $self->getAttr(name => 'inside_id'),
                    host_manager_id     => $self->getAttr(name => 'physicalhoster0_id'),
                    %args
                );
    };
    if($@) {
        $errmsg = "Wrong host attributes detected\n" . $@;
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Add power supply card if required
    eval {
        General::checkParams(args => \%args, required => [ "powersupplycard_id",
                                                           "powersupplyport_number" ]);

        my $powersupplycard = Entity::Powersupplycard->get(id => $args{powersupplycard_id});
        my $powersupply_id  = $powersupplycard->addPowerSupplyPort(
                                  powersupplyport_number => $args{powersupplyport_number}
                              );

        $host->setAttr(name  => 'host_powersupply_id', value => $powersupply_id);
    };
    if($@) {
        $log->info("No power supply card provided for host <" . $host->getAttr(name => 'host_id') . ">")
    }

    # Set initial state to down
    $host->setAttr(name => 'host_state', value => 'down:' . time);

    # Save the Entity in DB
    $host->save();

    return $host;
}

=head2 delHost

=cut

sub delHost {
    my $self = shift;
    my %args  = @_;
    my ($powersupplycard, $powersupplyid);

    General::checkParams(args => \%args, required => [ "host" ]);

    my $powersupplycard_id = $args{host}->getPowerSupplyCardId();
    if ($powersupplycard_id) {
        $powersupplycard = Entity::Powersupplycard->get(id => $powersupplycard_id);
        $powersupplyid   = $args{host}->getAttr(name => 'host_powersupply_id');
    }

    # Delete the host from db
    $args{host}->delete();

    if ($powersupplycard_id){
        $log->debug("Deleting powersupply with id <$powersupplyid> on the card : <$powersupplycard>");
        $powersupplycard->delPowerSupply(powersupply_id => $powersupplyid);
    }
}

1;
