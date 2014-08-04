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

=pod
=begin classdoc

Boot management interface. Boot managers must implement this interface
to provides boot configuration on the boot server required for booting nodes
in function of the boot method set for the node.

@since    2014-Jul-29
@instance hash
@self     $self

=end classdoc
=cut

package Manager::BootManager;
use parent Manager;

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");


sub methods {
    return {
        configureBoot => {
            description => 'set the boot configuration for the node',
        },
        applyBootConfiguration => {
            description => 'apply the boot configuration for the node',
        },
    };
}


=pod
=begin classdoc

Do the required configuration/actions to provides the boot mechanism for the node.

=end classdoc
=cut

sub configureBoot {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "node", "systemimage", "boot_policy" ],
                         optional => { "remove" => 0 });

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Workaround for the native HCM boot manager that requires the configuration
of the boot made in 2 steps.

Apply the boot configuration set at configureBoot

=end classdoc
=cut

sub applyBootConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "node", "systemimage", "boot_policy" ],
                         optional => { "remove" => 0 });

    throw Kanopya::Exception::NotImplemented();
}

1;
