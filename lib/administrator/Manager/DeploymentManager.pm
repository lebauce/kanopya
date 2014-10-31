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


sub methods {
    return {
        deployNode => {
            description => 'deploy a node from given system image.',
        },
        releaseNode => {
            description => 'remove the node from the deployment manager',
        },
    };
}


=pod
=begin classdoc

Deploy a node from given system image.

=end classdoc
=cut

sub deployNode {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'node', 'systemimage', 'boot_policy' ],
                         optional => { 'hypervisor' => undef, 'kernel_id' => undef,
                                       'deploy_on_disk' => 0, 'workflow' => undef });

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


=pod
=begin classdoc

Check params required for managing deployment of nodes.

=end classdoc
=cut

sub checkDeploymentManagerParams {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

Remove the deployment manager params entry from a hash ref.

=end classdoc
=cut

sub releaseDeploymentManagerParams {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}


=pod
=begin classdoc

@return the deployment manager parameters as an attribute definition.

=end classdoc
=cut

sub getDeploymentManagerParams {
    my ($self, %args) = @_;

    throw Kanopya::Exception::NotImplemented();
}

1;
