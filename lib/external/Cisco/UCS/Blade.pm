#    Copyright 2012 Hedera Technology SAS
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

package Cisco::UCS::Blade;
use base "Cisco::UCS::Object";

use warnings;
use strict;

sub KVM {
    my $self = shift;

    my $mgmt = $self->{ucs}->get(dn => $self->{dn} . "/mgmt/if-1");
    my $extip = $mgmt->{extIp};
    my $firmware = $self->{ucs}->get(dn => "sys/mgmt/fw-system");

    if ($firmware->{version} gt "1.4") {
        my $request = '<aaaGetNComputeAuthTokenByDn cookie="' . $self->{ucs}->{cookie} . '" ' .
                      'inCookie="' . $self->{ucs}->{cookie} . '" ' .
                      'inDn="' . $self->{dn} . '" ' .
                      'inNumberOf="2">' .
                      '</aaaGetNComputeAuthTokenByDn>';

        my $out = $self->{ucs}->_ucsm_request($request);
        my $user = $out->{outUser};

        my @tokens = split(',', $out->{outTokens});
        my $pass1 = $tokens[0];
        my $pass2 = $tokens[1];

        my $sp = $self->{assignedToDn};

        my $url = $self->{ucs}->{proto} . "://" . $self->{ucs}->{cluster} .
                  '/ucsm/kvm.jnlp?kvmIpAddr=' . $extip .
                  '&kvmUser=' . $user .
                  '&kvmPassword=' . $pass1 .
                  '&centraleUser=' . $user .
                  '&centralePassword=' . $pass2 .
                  '&chassisId=' . $self->{chassisId} .
                  '&slotId=' . $self->{slotId} .
                  '&tempunpw=true' .
                  '&frameTitle=' . $self->{dn};

        return $url;
    }
}

1;
