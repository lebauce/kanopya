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

package Kanopya::Test::TestOpenStack;
use parent Kanopya::Test;

use strict;
use warnings;

use TryCatch;
use Test::More;
use Test::Exception;


=pod
=begin classdoc

Test the OpenStack api methods.

=end classdoc
=cut

sub runTestSuite {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'component' ]);

    $args{component}->configure(api_username => 'tgenin',
                                api_password => 'doc@123',
                                keystone_url => '192.168.3.10',
                                tenant_name  => 'Doc');

    # Synchronize the existing infrastructure
    diag("Synchronize the existing infrastructure from component " . $args{component}->label);
    lives_ok {
        $args{component}->synchronize();

    } "Synchronize the existing infrastructure from component " . $args{component}->label;
}

1;
