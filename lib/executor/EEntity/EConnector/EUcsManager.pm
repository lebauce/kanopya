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

package EEntity::EConnector::EUcsManager;
use base "EEntity";
use base "EEntity::EHostManager";

use strict;
use warnings;

use General;
use Log::Log4perl "get_logger";
use Data::Dumper;
use DecisionMaker::HostSelector;

my $log = get_logger("executor");
my $errmsg;

sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "host", "econtext" ]);

    my $ucs = $self->_getEntity();
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

    my $ucs = $self->_getEntity();
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

    if ($args{ram_unit}) {
        $args{ram} .= $args{ram_unit};
        delete $args{ram_unit};
    }

    my $ucs = $self->_getEntity();
    $ucs->init();

    my $ou = $ucs->{ucs}->getAttr(name => "ucs_ou");

    # Get all free hosts of the specified host manager
    my @free_hosts = $self->_getEntity()->getFreeHosts();

    # Filter the one that match the contraints
    my @hosts = grep {
                    DecisionMaker::HostSelector->_matchHostConstraints(host => $_, %args)
                } @free_hosts;

    for my $host (@hosts) {
        my $blade = $ucs->{api}->get(dn      => $host->getAttr(name => "host_serial_number"),
                                     classId => "computeBlade");

        # Get a blade with no service profile assigned to it
        if (defined ($blade->{assignedToDn}) and $blade->{assignedToDn} eq "") {
            # Create a new service for the blade
            my @splitted = split(/\//, $blade->{dn});
            my $name = $splitted[-1];
            my $tmpl = $ucs->{api}->get(dn => $ou . "/ls-" . $args{service_profile_template_id});
            my $sp = $tmpl->instantiate_service_profile(name      => "kanopya-" . $name,
                                                        targetOrg => $ou);

            $sp->unbind();

            # Associate the new service profile to the blade
            $sp->associate(blade => $blade->{dn});

            $log->info("Waiting for blade to be associated");
            do {
                sleep 5;
                $sp = $ucs->{api}->get(dn => $sp->{dn});
                $log->info($sp->{dn} . " " . $sp->{assocState});
            } while ($sp->{assocState} ne "associated");

            my @ethernets = $sp->children("vnicEther");
            my $ethernet = $ethernets[0];
            # TODO: set host ifeacs to proper mac addrs.

            return $host;
        }
    }

    throw Kanopya::Exception::Internal(error => "No blade without a service profile attached were found");
}

1;
