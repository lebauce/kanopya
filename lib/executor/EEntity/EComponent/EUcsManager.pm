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

package EEntity::EComponent::EUcsManager;
use base "EEntity::EComponent";
use base "EManager::EHostManager";

use strict;
use warnings;

use General;
use Log::Log4perl "get_logger";
use Data::Dumper;
use DecisionMaker::HostSelector;

my $log = get_logger("");
my $errmsg;

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $ucs = $self->_entity;
    $ucs->init();
    my $blade = $ucs->{api}->get(dn      => $args{host}->getAttr(name => "host_serial_number"),
                                 classId => "computeBlade");
    my $sp = $ucs->{api}->get(dn => $blade->{assignedToDn});
    $sp->start();
}

sub stopHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $ucs = $self->_entity;
    $ucs->init();
    my $blade = $ucs->{api}->get(dn      => $args{host}->getAttr(name => "host_serial_number"),
                                 classId => "computeBlade");
    my $sp = $ucs->{api}->get(dn => $blade->{assignedToDn});
    $sp->stop();
}

=head2 getFreeHost

    Desc : Return one free host that match the criterias
    args : ram, cpu

=cut

sub getFreeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "service_profile_template_id", "ifaces" ]);

    my $ucs = $self->_entity;
    $ucs->init();

    my $ou = $ucs->{ucs}->getAttr(name => "ucs_ou");

    # Get all free hosts of the specified host manager
    my @free_hosts = $self->_entity->getFreeHosts();

    # Do not apply the 'ifaces' constraint as we can create (almost) as
    # many network interfaces as we want on a service profile
    delete $args{ifaces};

    # Filter the one that match the contraints
    my @hosts = grep {
                    DecisionMaker::HostSelector->_matchHostConstraints(host => $_, %args)
                } @free_hosts;

    for my $host (@hosts) {
        my $blade = $ucs->{api}->get(dn      => $host->getAttr(name => "host_serial_number"),
                                     classId => "computeBlade");

        my @splitted = split(/\//, $blade->{dn});
        my $name = $splitted[-1];
        my $sp_name = "kanopya-" . $name;

        # Get a blade with no service profile assigned to it
        if (defined ($blade->{assignedToDn}) and
            (($blade->{assignedToDn} eq ($ou . "/ls-" . $sp_name)) or ($blade->{assignedToDn} eq ""))) {

            my $sp;
            if ($blade->{assignedToDn} eq "") {
                # Create a new service for the blade
                $log->debug("Getting service profile template " . $args{service_profile_template_id});
                my $tmpl = $ucs->{api}->get(dn => $ou . "/ls-" . $args{service_profile_template_id});
                eval {
                    $log->debug("Retrieving service profile $sp_name");
                    $sp = $ucs->{api}->get(dn => $sp_name);
                };
                if ($@) {
                    $sp = $tmpl->instantiate_service_profile(name      => $sp_name,
                                                             targetOrg => $ou);
                }
            }
            else {
                $sp = $ucs->{api}->get(dn => $blade->{assignedToDn});
            }

            $log->info("Unbinding");
            $sp->unbind();

            # Associate the new service profile to the blade
            $log->info("Associating to blade");
            $sp->associate(blade => $blade->{dn});

            $log->info("Waiting for blade to be associated");
            do {
                sleep 5;
                $sp = $ucs->{api}->get(dn => $sp->{dn});
                $log->info($sp->{dn} . " " . $sp->{assocState});
            } while ($sp->{assocState} ne "associated");

            eval {
                for my $iface (@{$host->getIfaces()}) {
                    $host->removeIface(iface_id => $iface->getId);
                }
            };
            if ($@) {
                $log->info("Failed to remove interface $@");
            }

            my $pxe = 1;
            my @ethernets = $sp->children("vnicEther");
            @ethernets = sort { $a->{name} cmp $b->{name} } @ethernets;

            for my $ethernet (@ethernets) {
                my $ifname = $ethernet->{name};
                $ifname =~ s/^v//g;

                $host->addIface(
                    iface_name     => $ifname,
                    iface_mac_addr => $ethernet->{addr},
                    iface_pxe      => $pxe
                );

                $pxe = 0;
            }
                                     
            $sp->stop();

            return $host;
        }
        else {
            $log->debug("Blade " . $blade->{dn} . " is not usable");
        }
    }

    $log->info("No blade without a service profile attached were found");
    return undef;

    # We faced a very odd bug here : if we raise an exception
    # the 'onerun' method of the executor catches it, but $@ is
    # undefined !

    # throw Kanopya::Exception::Internal(error => "No blade without a service profile attached were found");
}

=head2 applyVLAN

    Desc: apply a VLAN on an interface of a host

=cut

sub applyVLAN {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'iface', 'vlan' ]);

    my $host = Entity->get(id => $args{iface}->getAttr(name => "host_id"));
    my $api = $self->_entity->init();
    my $blade = $api->get(dn => $host->getAttr(name => "host_serial_number"));
    my $sp = $api->get(dn => $blade->{assignedToDn});

    my @ethernets = $sp->children("vnicEther");
    for my $ethernet (@ethernets) {
        if ($ethernet->{name} eq 'v' . $args{iface}->getAttr(name => "iface_name")) {
            $log->info("Applying vlan " . $args{vlan}->vlan_name .
                       " on " . $ethernet->{name} . " interface of " . $host->getAttr(name => "host_serial_number"));
            $ethernet->applyVLAN(name   => $args{vlan}->vlan_name,
                                 delete => (defined ($args{delete}) and $args{delete}) ? 1 : 0);
        }
    }
}

1;
