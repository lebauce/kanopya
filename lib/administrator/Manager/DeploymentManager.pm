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

Node deployment interface.

@since    2014-Apr-9
@instance hash
@self     $self

=end classdoc
=cut

package Manager::DeploymentManager;
use base Manager;

use strict;
use warnings;

use Log::Log4perl "get_logger";
my $log = get_logger("");


sub methods { return {}; }


=pod
=begin classdoc

Deploy a node from given system image.

=end classdoc
=cut

sub deployNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node', 'systemimage' ],
                         optional => { 'workflow' => undef });

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Remove the node from the deployment manager.

=end classdoc
=cut

sub releaseNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node' ],
                         optional => { 'workflow' => undef });

    throw Kanopya::Exception::NotImplemented();
}

1;
