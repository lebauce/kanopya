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

use VMware::VIRuntime;

use General;

use Data::Dumper;
use Log::Log4perl "get_logger";
use Kanopya::Exceptions;
use Vsphere5Repository;
use Vsphere5Datacenter;
use Entity::Operation;
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
    },
    vsphere5_url => {
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

###############
# API methods #
###############

=head2 methods

    Desc: List methods accessible from API and permission need to access to them
    Args: null
    Return: List of methods with description and permissions

=cut

sub methods {
    return {
        'retrieveDatacenters'    =>  {
            'description'   =>  'Retrieve list of Datacenters',
            'perm_holder'   =>  'entity',
        },
        'retrieveClustersAndHypervisors'    =>  {
            'description'   =>  'Retrieve list of Clusters and Hypervisors (that are not in a cluster) hosted in a Datacenter',
            'perm_holder'   =>  'entity',
        },
        'retrieveHypervisors'    =>  {
            'description'   =>  'Retrieve list of Hypervisors hosted in a Cluster',
            'perm_holder'   =>  'entity',
        },
        'retrieveVirtualMachines'    =>  {
            'description'   =>  'Retrieve list of Virtual Machines hosted in an Hypervisor',
            'perm_holder'   =>  'entity',
        },
    };
}

=head2 retrieveDatacenters

    Desc: Retrieve list of all Datacenters
    Args: null
    Return: \@datacenter_list

=cut

sub retrieveDatacenters {
    my ($self) = @_;

    my $datacenter_views = $self->findEntityViews (
                             view_type      => 'Datacenter',
                             array_property => ['name'],
                         );
    return $datacenter_views;
}

=head2 retrieveClustersAndHypervisors

    Desc: Retrieve list of Clusters and Hypervisors (that are not in a cluster) hosted in a Datacenter
    Args: $datacenter_view
    Return: \%clusters_and_hypervisors_views

=cut

sub retrieveClustersAndHypervisors {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['datacenter_view']);
    my $datacenter_view = $args{datacenter_view};

    #A hash in which we add
        #type: 'cluster' for list of Clusters views and
        #type: 'hypervisor' for List of Hypervisors views
    my %clusters_and_hypervisors_views = (
                                     cluster    =>   undef,
                                     hypervisor =>   undef,
                                 );

    #Views of Cluster
    my $cluster_views = $self->findEntityViews (
                          view_type    => 'ClusterComputeResource',
                          begin_entity => $datacenter_view,
                      );
    @{$clusters_and_hypervisors_views{cluster}} = @{$cluster_views};

    #Views of Hypervisors that are NOT in a cluster
    #To find them,
    #TODO Test if Hypervisor.Parent NOT from type Cluster
        #hash for Hypervisor NOT in a Cluster
    my $hypervisor_hash_filter  = {};
    my $hypervisor_views        = $self->findEntityViews (
                                    view_type    => 'HostSystem',
                                    hash_filter  => $hypervisor_hash_filter,
                                    begin_entity => $datacenter_view,
                                );
    @{$clusters_and_hypervisors_views{hypervisor}} = @{$hypervisor_views};

    return \%clusters_and_hypervisors_views;
}

=head2 retrieveHypervisors

    Desc: Retrieve list of Hypervisors hosted in a Cluster
    Args: $cluster_view
    Return: \@hypervisor_views

=cut

sub retrieveHypervisors {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['cluster_view']);
    my $cluster_view = $args{cluster_view};

    #Views of Hypervisor that are in the cluster
    my $hypervisor_views = $self->findEntityViews (
                             view_type    => 'HostSystem',
                             begin_entity => $cluster_view,
                         );

    return $hypervisor_views;
}

=head2 retrieveVirtualMachines

    Desc: Retrieve list of Virtual Machines hosted in an Hypervisor
    Args: $hypervisor_view
    Return: \@vm_views

=cut

sub retrieveVirtualMachines {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['hypervisor_view']);
    my $hypervisor_view = $args{hypervisor_view};

    #Views of Virtual Machines that are in the Hypervisor
    my $vm_views = $self->findEntityViews (
                     view_type    => 'VirtualMachine',
                     begin_entity => $hypervisor_view,
                 );

    return $vm_views;
}

######################
# connection methods #
######################

=head2 connect

    Desc: Connect to a vCenter instance
    Args: $login, $pwd
 
=cut

sub connect {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['user_name', 'password', 'url']);

    eval {
        Util::connect($args{url}, $args{user_name}, $args{password});
    };
    if ($@) {
        $errmsg = 'Could not connect to vCenter server: '.$@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

=head2 disconnect

    Desc: End the vSphere session

=cut

sub disconnect {
    eval {
        Util::disconnect();
    };
    if ($@) {
        $errmsg = 'Could not disconnect from vCenter server: '.$@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

=head2 negociateConnection

    Desc: Check if a connection is established and create one if not

=cut

sub negociateConnection {
    my ($self,%args) = @_;

    $log->info('Checking if a session to vSphere is already opened');
    #try to grab a dummy entity to check if a session is opened
    my $view;
    eval {
        $view = Vim::find_entity_view(view_type      => 'Folder',
                                      filter         => {name => 'rootFolder'});
    };
    if ($@ =~ /no global session is defined/) {
        $log->info('opening a new session to vSphere');

        $self->connect(
            user_name => $self->vsphere5_login,
            password  => $self->vsphere5_pwd,
            url       => 'https://'.$self->vsphere5_url);
    }
    else {
        $log->info('A session toward vSphere is already opened');
    }
}

###########################
# vsphere objects methods #
###########################

=head2 getView

    Desc: get a vsphere managed object view
    Args: $mor (managed object reference)
    Return: $view

=cut

sub getView {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['mo_ref']);

    $self->negociateConnection();

    my $view;
    eval {
        $view = Vim::get_view(mo_ref => $args{mo_ref});
    };
    if ($@) {
        $errmsg = 'Could not get view: '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $view;
}


=head2 findEntityView

    Desc: find a view of a specified managed object type
    Args: $view_type (HostSystem,VirtualMachine,Datacenter,Folder,ResourcePool,
                        ClusterComputeResource or ComputeResource),
          %hash_filter, @array_property, $begin_entity view
    Return: the managed entity view

=cut

sub findEntityView {
    my ($self,%args) = @_;

    #Check of Global parameters
    General::checkParams(args     => \%args,
                         required => ['view_type','hash_filter'],
                         optional => {
                             'array_property' => undef,
                             'begin_entity'   => undef,
                         });

    #Check of Filter parameters
    General::checkParams(args     => $args{hash_filter},
                         required => ['name'],);

    $self->negociateConnection();

    my $hash_filter  = $args{hash_filter};
    my $view_type    = $args{view_type};
    my $begin_entity = $args{begin_entity};

    my @array_property = undef;
    if ($args{array_property}) {
        @array_property = @{$args{array_property}};
    }

    my $view;
    eval {
        if (defined $begin_entity) {
            $view = Vim::find_entity_view(view_type      => $view_type,
                                          filter         => $hash_filter,
                                          properties     => \@array_property,
                                          begin_entity   => $begin_entity,);
        }
        else {
            $view = Vim::find_entity_view(view_type      => $view_type,
                                          filter         => $hash_filter,
                                          properties     => \@array_property,);
        }
    };
    if ($@) {
        $errmsg = 'Could not get entity '.$hash_filter->{name}.' of type '.$view_type.': '.$@."\n";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $view;
}

=head2 findEntityViews

    Desc: find views of a specified managed object type
    Args: $view_type (HostSystem,VirtualMachine,Datacenter,Folder,ResourcePool,
                        ClusterComputeResource or ComputeResource),
          %hash_filter, @array_property, $begin_entity view
    Return: the managed entity views

=cut

sub findEntityViews {
    my ($self,%args) = @_;

    #Check of Global parameters
    General::checkParams(args     => \%args,
                         required => ['view_type'],
                         optional => {
                             'hash_filter'    => undef,
                             'array_property' => undef,
                             'begin_entity'   => undef,
                         });

    $self->negociateConnection();

    my $hash_filter  = $args{hash_filter};
    my $view_type    = $args{view_type};
    my $begin_entity = $args{begin_entity};

    my @array_property = undef;
    if ($args{array_property}) {
        @array_property = @{$args{array_property}};
    }

    my $views;
    eval {
        if (defined $begin_entity) {
            $views = Vim::find_entity_views(
                         view_type    => $view_type,
                         filter       => $hash_filter,
                         properties   => \@array_property,
                         begin_entity => $begin_entity,
                     );
        }
        else {
            $views = Vim::find_entity_views(
                         view_type  => $view_type,
                         filter     => $hash_filter,
                         properties => \@array_property,
                     );
        }
    };
    if ($@) {
        $errmsg = 'Could not get entities of type '.$view_type.': '.$@."\n";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $views;
}

#############################
## synchronization methods ##
#############################

=head2 synchronize

    Desc: synchronize the component with its related vSphere infrastructure.
    Args: $synchronize_item, the object to be synchronized in the vsphere entity with Kanopya
          \%args is also relayed to the operation
=cut

sub synchronize {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['synchronize_item']);

    my %synchronize_functions = (
        'cluster'    => 'synchronizeCluster',
        'datacenter' => 'synchronizeDatacenter',
        'vm'         => 'synchronizeVm',
        'network'    => 'synchronizeNetwork',
    );

    my $synchronize_method = $synchronize_functions{$args{synchronize_item}};

    delete $args{synchronize_item};

    $self->$synchronize_method(\%args);
}

=head2 synchronizeCluster

    Desc: synchronize the component with a cluster in a given datacenter 
    Args: $datacenter_name, $service_provider_id
 
=cut 

sub synchronizeCluster {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['service_provider',
                                                      'datacenter_name']);

    $self->negociateConnection();

    my $datacenter       = $self->getDatacenters(datacenter_name => $args{datacenter_name});
    my $cluster_name     = $args{service_provider}->service_provider_name;
    my $datacenter_view  = $self->findEntityView(
                               view_type   => 'Datacenter',
                               hash_filter => {
                                   name => $args{datacenter_name},
                               });
    my $cluster_views    = $self->findEntityView(
                               view_type    => 'ClusterComputeResource',
                               hash_filter  => {
                                   name => $cluster_name
                               },
                               begin_entity => $datacenter_view,
                           );
    my $hypervisors      = $cluster_views->host;

    # Use the first kernel found...
    my $kernel = Entity::Kernel->find(hash => {});

    foreach my $hypervisor (@$hypervisors) {

        my $hypervisor_view = $self->getView(mo_ref => $hypervisor);
        my $host_state;

        #we define the state time as now
        if ($hypervisor_view->runtime->connectionState->val eq 'disconnected') {
            $host_state = 'down: '.time();
        }
        elsif ($hypervisor_view->runtime->connectionState->val eq 'connected') {
            $host_state = 'up: '.time();
        }
        elsif ($hypervisor_view->runtime->connectionState->val eq 'notResponding') {
            $host_state = 'broken: '.time();
        }

        my $hv = Entity::Host::Hypervisor->new(
                     host_manager_id    => $self->id,
                     kernel_id          => $kernel->id,
                     host_serial_number => '',
                     host_desc          => $cluster_name.' hypervisor',
                     active             => 1,
                     host_ram           => $hypervisor_view->hardware->memorySize,
                     host_core          => $hypervisor_view->summary->hardware->numCpuCores,
                     host_hostname      => $hypervisor_view->name,
                     host_state         => $host_state,
                 );

        #promote new hypervisor class to a vsphere5Hypervisor one
        $self->addHypervisor(host => $hv, datacenter_id => $datacenter->id);

        my $node = Externalnode->new(
                       externalnode_hostname => $hypervisor_view->name,
                       service_provider_id   => $args{service_provider_id},
                       externalnode_state    => 'enabled',
                   );
    }
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

=head2 getDatacenters

    Desc: get all the datacenters attached to this vsphere component
    Return: $datacenters

=cut

sub getDatacenters {
    my ($self,%args) = @_;

    my $datacenters;

    if (defined $args{datacenter_name}) {
        $datacenters  = Vsphere5Datacenter->find(
                            hash => { 
                                vsphere5_id              => $self->id,
                                vsphere5_datacenter_name => $args{datacenter_name},
                            });
    }
    else {
        $datacenters  = Vsphere5Datacenter->search(
                               hash => { vsphere5_id => $self->id });
    }

    return $datacenters; 
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

=head2 powerOnVm

    Desc: start a VM registerd on vSphere

=cut

sub powerOnVm {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'hypervisor', 'vm']);

    my $host_name = $args{hypervisor}->host_hostname;
    my $vm_name   = $args{vm}->host_hostname;

    #get the HostSystem view
    my $host_view = $self->findEntityView(view_type   => 'HostSystem',
                                          hash_filter => {
                                              'name' => $host_name
                                          });
    my $host_vms = $host_view->vm;
 
    #maybe find a better way to do that? 
    foreach my $vm (@$host_vms) {
        my $guest = $self->getView(mo_ref => $vm);
        if ($guest->name eq $vm_name) {
            $guest->PowerOnVM();
        }
    }
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
