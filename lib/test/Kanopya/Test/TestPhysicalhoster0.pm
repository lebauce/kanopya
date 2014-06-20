#    Copyright © 2014 Hedera Technology SAS
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

Test suite for component Physicalhoster0.

=end classdoc
=cut

package Kanopya::Test::TestPhysicalhoster0;
use parent Kanopya::Test;

use strict;
use warnings;

use TryCatch;
use Test::More;
use Test::Exception;

use Entity::Host;
use EEntity;


=pod
=begin classdoc

Test the Physicalhoster0 api methods.

=end classdoc
=cut

sub runTestSuite {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'component' ]);

    my $serial_number = "serial" . time;

    # Find an existing bootable host dedicated to test on node deployment provided
    # by the continous integration plateforme environement.
    diag("Find and existing bootable host");
    my $existing = Entity::Host->find(hash => { host_state => { LIKE => 'down:%' } });
    my $iface = $existing->find(related => 'ifaces', hash => { iface_name => 'eth0' });


    # Create a logical volume
    diag("Creating host $serial_number");
    my $operation;
    lives_ok {
        $operation = $args{component}->createHost(
                         host_core => 4,
                         host_ram  => 4,
                         host_serial_number => $serial_number,
                     );

        $class->waitOperartion(operation => $operation);

    } "Creating host $serial_number";

    diag("Retrieve the created host");
    my $host;
    lives_ok {
        try {
            $host = Entity::Host->find(hash => { host_serial_number => $serial_number });
        }
        catch ($err) {
            throw Kanopya::Exception::Test(error => "Unable to find the created host: $err");
        }
    } "Retrieve the created host";


    diag('Assign ip to the existing host');
    $iface->host_id($host->id);
    $iface->iface_pxe(1);
    $iface->assignIp(ip_addr => '192.168.1.2');

    diag("Start the host");
    lives_ok {
        # Use the EEntity directly to simulate the merge with Entity and EEntity.
        EEntity->new(entity => $args{component})->startHost(host => EEntity->new(entity => $host));
    } "Start the host";

}

1;
