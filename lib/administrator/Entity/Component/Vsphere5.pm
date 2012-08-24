# Vsphere5.pm - Vsphere5 component
#    Copyright © 2011-2012 Hedera Technology SAS
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

package Entity::Component::Vsphere5;
use base "Entity::Component";
use base "Manager::HostManager::VirtualMachineManager";

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl "get_logger";
use Kanopya::Exceptions;
use Vsphere5Repository;
use Entity::ContainerAccess;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    vsphere5_pwd => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    vsphere5_login => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    }
};

sub getAttrDef { return ATTR_DEF; }

=head2 checkHostManagerParams

=cut

sub checkHostManagerParams {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'ram', 'core' ]); 
}

###########################
## configuration methods ##
###########################

=head 2 setConf

    Desc: Define the component configuration
    Args: \%conf

=cut

sub setConf {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['conf']);

    my $conf = $args{conf};

    if (defined $conf->{login}) {
        $self->setAttr(name => 'vsphere5_login', value => $conf->{login});
        $self->save();
    }
    if (defined $conf->{password}) {
        $self->setAttr(name => 'vsphere5_pwd', value => $conf->{password});
        $self->save();
    }
}


=head 2 getConf

    Desc: Give the component configuration
    Return: \%conf

=cut

sub getConf {
    my ($self,%args) = @_;

    my %conf;

    $conf{login}    = $self->vsphere5_login;
    $conf{password} = $self->vsphere5_pwd;

    return \%conf;
}

=head2 addRepository

    Desc: Create a new repository for vSphere usage
    Args: $repository_name, $container_access 
    Return: newly created repository object

=cut

sub addRepository {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['repository_name', 'container_access_id']);

    my $repository = Vsphere5Repository->new(vsphere5_id         => $self->id,
                                             repository_name     => $args{repository_name}, 
                                             container_access_id => $args{container_access_id},
                     );

    return $repository;
}

=head2 getRepository

    Desc: get a repository corresponding to a container access
    Args: $container_access,
    Return: $repository object

=cut

sub getRepository {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['container_access_id']);

    my $repository = Vsphere5Repository->find(hash => {
                         container_access_id => $args{container_access_id} }
                     );

    if (! defined $repository) {
        throw Kanopya::Exception::Internal(error => "No repository configured for Vsphere  " .$self->id);
    }
 
    return $repository;
}

1;
