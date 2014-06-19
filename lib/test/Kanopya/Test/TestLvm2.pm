#    Copyright © 2011 Hedera Technology SAS
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

Test suite for component Lvm2.

=end classdoc
=cut

package Kanopya::Test::TestLvm2;
use parent Kanopya::Test;

use strict;
use warnings;

use TryCatch;
use Test::More;
use Test::Exception;


=pod
=begin classdoc

Test the Lvm2 api methods.

=end classdoc
=cut

sub runTestSuite {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'component' ]);

    my $volumename = "test-logical-volume-" . time;

    # Create a logical volume
    diag("Creating logical volume $volumename");
    my $operation;
    lives_ok {
        $operation = $args{component}->createDisk(name       => $volumename,
                                                  size       => 1024,
                                                  filesystem => "ext3");
        $class->waitOperartion(operation => $operation);

    } "Creating logical volume $volumename";

    diag("Check the underlying middleware to ensure the logical volume has been properly created");
    lives_ok {
        my $grep = EEntity->new(entity => $operation)->getEContext->execute(
                       command => "lvdisplay -c | grep $volumename"
                   );

        if ($grep->{exitcode} != 0) {
            throw Kanopya::Exception::Test(error => "Logical volume $volumename seems to not be created.");
        }
    } "Check the underlying middleware to ensure the logical volume has been properly created";

    diag("Retrieve the created lovm container");
    my $container;
    lives_ok {
        try {
            $container = Entity::Container::LvmContainer->find(hash => { container_name => $volumename });
        }
        catch ($err) {
            throw Kanopya::Exception::Test(error => "Unable to find the created container: $err");
        }
    } "Retrieve the created lovm container";

    diag("Remove logical volume $volumename");
    lives_ok {
        $operation = $args{component}->removeDisk(container => $container);

        $class->waitOperartion(operation => $operation);
    } "Retrieve the created lovm container";

    diag("Check the underlying middleware to ensure the logical volume has been properly removed");
    lives_ok {
        my $grep = EEntity->new(entity => $operation)->getEContext->execute(
                       command => "lvdisplay -c | grep $volumename"
                   );

        if ($grep->{exitcode} != 1) {
            throw Kanopya::Exception::Test(error => "Logical volume $volumename seems to still exists.");
        }
    } "Check the underlying middleware to ensure the logical volume has been properly removed";
}

1;
