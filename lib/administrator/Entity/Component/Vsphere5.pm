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
use Vsphere5Datacenter;
use Entity::Host::VirtualMachine::Vsphere5Vm;
use Entity::Host::Hypervisor::Vsphere5Hypervisor;
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
    if (defined $conf->{repositories}) {
        while (my ($repo,$container) = each (%{$conf->{repositories}})) {
            $self->addRepository(repository_name     => $repo,
                                 container_access_id => $container->{container_access_id});
        }
    }
}


=head 2 getConf

    Desc: Give the component configuration
    Return: \%conf

=cut

sub getConf {
    my ($self,%args) = @_;

    my %conf;
    my @repos = Vsphere5Repository->search(hash => { vsphere5_id => $self->id });

    $conf{login}        = $self->vsphere5_login;
    $conf{password}     = $self->vsphere5_pwd;
    $conf{repositories} = \@repos;

    return \%conf;
}

=head2 getHypervisors

    Desc: Return the list of hypervisors managed by the component
    Return: \@hypervisors

=cut

sub getHypervisors {
    my $self = shift;

    my @hypervisors = Entity::Host::Hypervisor::Vsphere5Hypervisor->search(
                          hash => { vsphere5_id => $self->id} );

    return wantarray ? @hypervisors : \@hypervisors;
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

=head2 addDatacenter

    Desc: register a new vsphere datacenter
    Args: $datacenter_name,

=cut

sub addDatacenter {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['datacenter_name']);

    my $datacenter = Vsphere5Datacenter->new(
                         vsphere5_datacenter_name => $args{datacenter_name},
                         vsphere5_id              => $self->id,
                     );

    return $datacenter;
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

#######################
## vm's manipulation ##
#######################

=head2 addVM

    Desc: register a new vsphere VM into kanopya 
    Args: $host, $hypervisor, $guest_id
    Return: an instance of vsphere5_vm 

=cut

sub addVM {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'guest_id' ]);

    my $vsphere5vm = Entity::Host::VirtualMachine::Vsphere5Vm->promote(
                         promoted          => $args{host},
                         vsphere5_id       => $self->id,
                         vsphere5_guest_id => $args{guest_id},
                     );

    return $vsphere5vm;
}

###############################
## hypervisors' manipulation ##
###############################

=head2 addHypervisor

    Desc: register a new vsphere hypervisor into kanopya 
    Args: $host,$datacenter_id
    Return: a new instance of vsphere5_hypervisor 

=cut

sub addHypervisor {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'datacenter_id' ]);

    my $hypervisor_type = 'Entity::Host::Hypervisor::Vsphere5Hypervisor';

    return $hypervisor_type->promote(
               promoted                => $args{host},
               vsphere5_id             => $self->id,
               vsphere5_datacenter_id  => $args{datacenter_id}
           ); 
}

1;
