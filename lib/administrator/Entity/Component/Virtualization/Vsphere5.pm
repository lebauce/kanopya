#    Copyright © 2011-2012 Hedera Technology SAS
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

Vsphere component version 5.
-> Manage connection to a vsphere instance (also works with single hypervisors instances)
-> Set and get component configuration
-> Retrieve vsphere entities (datacenters, clusters, hypervisors, vms)
-> Register vsphere entities into Kanopya (same than retrieve plus datastores/repositories)
-> Power on vms
-> promote virtual machines classes to Vsphere5Vm and hypervisors to Vsphere5Hypervisor

@since
@instance hash
@self $self

=end classdoc

=cut

package Entity::Component::Virtualization::Vsphere5;
use base "Entity::Component::Virtualization";
use base "Manager::HostManager::VirtualMachineManager";

use strict;
use warnings;

use VMware::VIRuntime;

use General;
use Kanopya::Exceptions;
use Entity::Repository::Vsphere5Repository;
use Entity::Component::Vsphere5::Vsphere5Datacenter;
use Entity::User;
use Entity::Policy;
use Entity::ServiceTemplate;
use Entity::ServiceProvider::Cluster;
use Entity::Host::VirtualMachine::Vsphere5Vm;
use Entity::Host::Hypervisor::Vsphere5Hypervisor;
use Entity::ContainerAccess;
use Entity::Host;
use Node;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    repositories => {
        label       => 'Virtual machine images repositories',
        type        => 'relation',
        relation    => 'single_multi',
        is_editable => 1,
        specialized => 'vsphere5_repository'
    },
    vsphere5_login => {
        label        => 'Login',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1
    },
    vsphere5_pwd => {
        label        => 'Password',
        type         => 'password',
        pattern      => '^.+$',
        is_mandatory => 1,
        is_editable  => 1
    },
    vsphere5_url => {
        label        => 'URL',
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_editable  => 1,
        is_mandatory => 1
    },
    # TODO: move this virtual attr to HostManager attr def when supported
    host_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }

=pod

=begin classdoc

Declare the list of methods accessible from the API and their permissions

@return the list of methods with their descriptions and permissions

=end classdoc

=cut

sub methods {
    return {
        retrieveDatacenters =>  {
            description =>  'Retrieve a list of Datacenters',
        },
        retrieveClustersAndHypervisors =>  {
            description =>  'Retrieve a list of Clusters and Hypervisors (that are not in a cluster) ' .
                            'registered in a Datacenter',
        },
        retrieveClusterHypervisors =>  {
            description =>  'Retrieve a list of Hypervisors that are registered in a Cluster',
        },
        retrieveHypervisorVms =>  {
            description =>  'Retrieve a list of vms registered under a vsphere hypervisor',
        },
        register =>  {
            description =>  'Register a new item with the vsphere component',
        },
    };
}

=pod
=begin classdoc

Return the boot policies for the host ruled by this host manager

=end classdoc
=cut

sub getBootPolicies {
    return (Manager::HostManager->BOOT_POLICIES->{virtual_disk},
            Manager::HostManager->BOOT_POLICIES->{pxe_iscsi},
            Manager::HostManager->BOOT_POLICIES->{pxe_nfs});
}


=pod
=begin classdoc

@return the manager params definition.

=end classdoc
=cut

sub getManagerParamsDef {
    my ($self, %args) = @_;

    return {
        %{ $self->SUPER::getManagerParamsDef },
        core => {
            label        => 'Initial CPU number',
            type         => 'integer',
            unit         => 'core(s)',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        ram => {
            label        => 'Initial RAM amount',
            type         => 'integer',
            unit         => 'byte',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        max_core => {
            label        => 'Maximum CPU number',
            type         => 'integer',
            unit         => 'core(s)',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
        max_ram => {
            label        => 'Maximum RAM amount',
            type         => 'integer',
            unit         => 'byte',
            pattern      => '^\d*$',
            is_mandatory => 1
        },
    };
}

sub checkHostManagerParams {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'ram', 'core', 'max_core', 'max_ram' ]);
}

sub getHostManagerParams {
    my $self = shift;
    my %args = @_;

    my $definition = $self->getManagerParamsDef();
    return {
        core     => $definition->{core},
        ram      => $definition->{ram},
        max_core => $definition->{max_core},
        max_ram  => $definition->{max_ram},
    };
}


=pod
=begin classdoc

Get the basic configuration of the Vsphere component

@return %base_configuration

=end classdoc
=cut

sub getBaseConfiguration {
    return {
        vsphere5_login      => 'login',
        vsphere5_pwd        => 'password',
        vsphere5_url        => '127.0.0.1'
    };
}

=pod

=begin classdoc

Try to open a connection to a vCenter or ESXi instance

@param login the user name that will be used for the connection
@param pwd the user's password
@param url the url of the vCenter or ESXi instance

=end classdoc

=cut

sub connect {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['user_name', 'password', 'url']);

    eval {
        Util::connect($args{url}, $args{user_name}, $args{password});
    };
    if ($@) {
        $errmsg = 'Could not connect to vCenter server: '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    return;
}

=pod

=begin classdoc

End a session to a vCenter or ESXi instance

=end classdoc

=cut

sub disconnect {
    eval {
        Util::disconnect();
    };
    if ($@) {
        $errmsg = 'Could not disconnect from vCenter server: '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    $log->debug('A connection to vSphere has been closed');
    return;
}

=pod

=begin classdoc

Check if a connection is established and if not create one using the component configuration

=end classdoc

=cut

sub negociateConnection {
    my ($self,%args) = @_;

    $log->debug('Checking if a session to vSphere is already opened');
    #try to grab a dummy entity to check if a session is opened
    my $sc;
    eval {
        $sc = Vim::get_service_content;
    };
    if ($@ =~ /no global session is defined/ ||
        $@ =~ /session object is uninitialized or not logged in/) {
        $log->debug('opening a new session to vSphere');

        $self->connect(
            user_name => $self->vsphere5_login,
            password  => $self->vsphere5_pwd,
            url       => 'https://'.$self->vsphere5_url,
        );
        return;
    }
    else {
        $log->debug('A session toward vSphere is already opened');
        return;
    }
}

=pod

=begin classdoc

=head2 retrieveDatacenters

Retrieve a list of all datacenters

@param id_request ID of request (used to differentiate UI requests)

@return: \@datacenter_infos

=end classdoc

=cut

sub retrieveDatacenters {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, optional => {'id_request' => undef});

    my @datacenters_infos;

    my $datacenter_views;
    eval {
        $datacenter_views = $self->findEntityViews(
                                   view_type      => 'Datacenter',
                                   array_property => ['name'],
                            );
    };
    if ($@) {
        my $errmsg = 'Error in datacenters retrieval:' . $@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    foreach my $datacenter_view (@$datacenter_views) {
        my %datacenter_infos = (
            name => $datacenter_view->name,
            type => 'datacenter',
         );
        push @datacenters_infos, \%datacenter_infos;
    }

    my $response = defined $args{id_request} ?
                       {
                           id_response => $args{id_request},
                           items_list  => \@datacenters_infos,
                       } :
                       \@datacenters_infos;

    return $response;
}

=pod

=begin classdoc

=head2 retrieveClustersAndHypervisors

Retrieve a list of Clusters and Hypervisors (that are not in a cluster)
hosted in a given Datacenter

@param datacenter_name the datacenter name
@param id_request ID of request (used to differentiate UI requests)

@return \@clusters_and_hypervisors_infos

=end classdoc

=cut

sub retrieveClustersAndHypervisors {
    my ($self,%args) = @_;

    General::checkParams(
        args => \%args,
        required => ['datacenter_name'],
        optional => {'id_request' => undef}
    );

    my @clusters_hypervisors_infos;
    my $datacenter_name = $args{datacenter_name};

    #Find datacenter view
    my $datacenter_view = $self->findEntityView(
                              view_type   => 'Datacenter',
                              hash_filter => { name => $datacenter_name }
                          );
    #get datacenter host folder
    my $host_folder = $self->getView(mo_ref => $datacenter_view->hostFolder);

    #We only gather ClusterComputeResource or ComputeResource
    CHILD:
    foreach my $child (@{ $host_folder->childEntity }) {

        my $child_view = $self->getView(mo_ref => $child);
        my $compute_resource_infos;

        if (ref ($child_view) eq 'ClusterComputeResource') {
            $compute_resource_infos = {
                name => $child_view->name,
                type => 'cluster',
            };
        }
        elsif (ref ($child_view) eq 'ComputeResource') {
            my $view = $self->getView(mo_ref => $child_view->host->[0]);
            my $uuid = $view->hardware->systemInfo->uuid;

            $compute_resource_infos = {
                name => $child_view->name,
                type => 'hypervisor',
                uuid => $uuid,
            };
        }
        else {
            next CHILD;
        }

        push @clusters_hypervisors_infos, $compute_resource_infos;
    }

    my $response = defined $args{id_request} ?
                       {
                           id_response => $args{id_request},
                           items_list  => \@clusters_hypervisors_infos,
                       } :
                       \@clusters_hypervisors_infos;

    return $response;
}

=pod

=begin classdoc

=head2 retrieveClusterHypervisors

Retrieve a cluster's hypervisors

@param cluster_name the name of the target cluster
@param datacenter_name the name of the cluster's datacenter
@param id_request ID of request (used to differentiate UI requests)

@return \@hypervisors_infos

=end classdoc

=cut

sub retrieveClusterHypervisors {
    my ($self,%args) = @_;

    General::checkParams(
        args => \%args,
        required => ['cluster_name', 'datacenter_name'],
        optional => {'id_request' => undef}
    );

    #retrieve datacenter and cluster views
    my $datacenter_view = $self->findEntityView(
                              view_type   => 'Datacenter',
                              hash_filter => { name => $args{datacenter_name}},
                          );

    my $cluster_view    = $self->findEntityView(
                              view_type    => 'ClusterComputeResource',
                              hash_filter  => { name => $args{cluster_name}},
                              begin_entity => $datacenter_view,
                          );

    #retrieve the cluster's hypervisors details
    my $hypervisor_views  = $self->getViews(mo_ref_array => $cluster_view->host);
    my @hypervisors_infos;

    foreach my $hypervisor_view (@$hypervisor_views) {
        my %hypervisor_infos = (
            name => $hypervisor_view->name,
            type => 'clusterHypervisor',
            uuid => $hypervisor_view->hardware->systemInfo->uuid,
        );

        push @hypervisors_infos, \%hypervisor_infos;
    }

    my $response = defined $args{id_request} ?
                       {
                           id_response => $args{id_request},
                           items_list  => \@hypervisors_infos,
                       } :
                       \@hypervisors_infos;

    return $response;
}

=pod

=begin classdoc

=head2 retrieveHypervisorVms

Retrieve all the VM from a vsphere hypervisor

@param datacenter_name the name of the hypervisor's datacenter
@param hypervisor_name the name of the target hypervisor
@param id_request ID of request (used to differentiate UI requests)

@return \@vms_infos

=end classdoc

=cut

sub retrieveHypervisorVms {
    my ($self,%args) = @_;

    General::checkParams(
        args => \%args,
        required => [ 'datacenter_name', 'hypervisor_uuid' ],
        optional => { 'id_request' => undef }
    );

    #retrieve views
    my $datacenter_view = $self->findEntityView(
                              view_type   => 'Datacenter',
                              hash_filter => { name => $args{datacenter_name}},
                          );

    my $hypervisor_view = $self->findEntityView(
                              view_type    => 'HostSystem',
                              hash_filter  => {
                                  'hardware.systemInfo.uuid' => $args{hypervisor_uuid}
                              },
                              begin_entity => $datacenter_view,
                          );

    #get vms details
    my $vm_views = $self->getViews(mo_ref_array => $hypervisor_view->vm);
    my @vms_infos;

    foreach my $vm_view (@$vm_views) {
        my $vm_infos = {
            name => $vm_view->name,
            type => 'vm',
            uuid => $vm_view->config->uuid,
        };

        push @vms_infos, $vm_infos;
    }

    my $response = defined $args{id_request} ?
                       {
                           id_response => $args{id_request},
                           items_list  => \@vms_infos,
                       } :
                       \@vms_infos;

    return $response;
}

=pod

=begin classdoc

Get a vsphere managed object view

@param mo_ref the managed object reference

@return $view

=end classdoc

=cut

sub getView {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'mo_ref' ]);

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

=pod

=begin classdoc

Get views of vsphere managed objects

@param mo_ref_array array of managed object references

@return views of managed objects

=end classdoc

=cut

sub getViews {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'mo_ref_array' ]);

    $self->negociateConnection();

    my $views;
    eval {
        $views = Vim::get_views(mo_ref_array => $args{mo_ref_array});
    };
    if ($@) {
        $errmsg = 'Could not get views: '.$@;
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $views;
}

=pod

=begin classdoc

Find a view of a specified managed object type

@param view_type the type of the requested view. Can be one of the following:
    - HostSystem
    - VirtualMachine
    - Datacenter
    - Folder
    - ResourcePool
    - ClusterComputeResource
    - ComputeResource
@param hash_filter a hash containing the filter to be applied to the request

@optional array_property an array containing properties filter to be applied to the request
@optional begin_entity_view the inventory point where the function must start the research.
          Used to delimit the search to a specific sub-folder in the vsphere arborescence

@return view a managed entity view

=end classdoc

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

    $self->negociateConnection();

    my $hash_filter  = $args{hash_filter};
    my $view_type    = $args{view_type};
    my $begin_entity = $args{begin_entity};

    my $array_property = undef;
    if ($args{array_property}) {
        $array_property = $args{array_property};
    }

    my $view;
    eval {
        if (defined $begin_entity) {
            $view = Vim::find_entity_view(view_type    => $view_type,
                                          filter       => $hash_filter,
                                          properties   => $array_property,
                                          begin_entity => $begin_entity,);
        }
        else {
            $view = Vim::find_entity_view(view_type  => $view_type,
                                          filter     => $hash_filter,
                                          properties => $array_property,);
        }
    };
    if ($@) {
        $errmsg = 'Could not get entity '.$hash_filter->{name}.' of type '.$view_type.': '.$@."\n";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $view;
}

=pod

=begin classdoc

Find some views of a specified managed object type

@param view_type the type of the requested views. Can be one of the following:
    - HostSystem
    - VirtualMachine
    - Datacenter
    - Folder
    - ResourcePool
    - ClusterComputeResource
    - ComputeResource
@param hash_filter a hash containing the filter to be applied to the request

@optional array_property an array containing properties filter to be applied to the request
@optional begin_entity_view the inventory point where the function must start the research.
          Used to delimit the search to a specific sub-folder in the vsphere arborescence

@return views a list of managed entity views

=end classdoc

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

    my $array_property = undef;
    if ($args{array_property}) {
        $array_property = $args{array_property};
    }

    my $views;
    eval {
        if (defined $begin_entity) {
            $views = Vim::find_entity_views(
                         view_type    => $view_type,
                         filter       => $hash_filter,
                         properties   => $array_property,
                         begin_entity => $begin_entity,
                     );
        }
        else {
            $views = Vim::find_entity_views(
                         view_type  => $view_type,
                         filter     => $hash_filter,
                         properties => $array_property,
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

=pod

=begin classdoc

=head2 register

Register vSphere items into kanopya service providers

@param register_items a list of objects to the registered into Kanopya

@optional parent the parent object of the current item to be registered

@return registered_items a list of the registered items. Can be service providers or datacenters

=end classdoc

=cut

sub register {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['register_items'],
                                         optional => {
                                             parent => undef,
                                         });

    my @register_items = @{ $args{register_items} };

    my %register_methods = (
        'cluster'    => 'registerCluster',
        'datacenter' => 'registerDatacenter',
        'hypervisor' => 'registerHypervisor',
        'vm'         => 'registerVm',
        'network'    => 'registerNetwork',
    );

    my @registered_items;
    foreach my $register_item (@register_items) {
        my $register_method = $register_methods{$register_item->{type}};

        my $registered_item;
        eval {
            $registered_item = $self->$register_method(
                                   name   => $register_item->{name},
                                   parent => $args{parent},
                                   uuid   => $register_item->{uuid},
                               );
        };
        if ($@) {
            $errmsg = 'Could not register '. $register_item->{name} .' in Kanopya: '. $@;
            throw Kanopya::Exception::Internal(error => $errmsg);
        }

        push @registered_items, $registered_item;

        if (defined ($register_item->{children}) &&
            scalar(@{ $register_item->{children} }) != 0) {

            $self->register(register_items => $register_item->{children},
                            parent         => $registered_item);
        }
    }

    return \@registered_items;
}

=pod

=begin classdoc

Register a new vsphere datacenter into Kanopya.
Check if the datacenter is already registered and linked to this component

@param name the name of the datacenter to be registered

@return datacenter the registered datacenter or an already existing one

=end classdoc

=cut

sub registerDatacenter {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['name']);

    #First we check if the datacenter already exist in Kanopya
    my $datacenter;
    eval {
        $datacenter = Entity::Component::Vsphere5::Vsphere5Datacenter->find(hash => {
                          vsphere5_datacenter_name => $args{name},
                          vsphere5_id              => $self->id,
                      });
    };
    if ($@) {
        eval {
            $datacenter = Entity::Component::Vsphere5::Vsphere5Datacenter->new(
                              vsphere5_datacenter_name => $args{name},
                              vsphere5_id              => $self->id
                          );
        };
        if ($@) {
            $errmsg = 'Datacenter '. $args{name} .' could not be created: '. $@;
            throw Kanopya::Exception::Internal(error => $errmsg);
        }

        return $datacenter;
    }
    else {
        $errmsg  = 'The datacenter '. $args{name} .' already exist in kanopya ';
        $errmsg .= 'with ID '. $datacenter->id;
        $errmsg .= ' and is already associated with this component (id '. $self->id .')';
        $log->info($errmsg);

        return $datacenter;
    }
}

=pod

=begin classdoc

=head2 registerVm

Register a new virtual machine to match a vsphere vm
One cluster is created by vm registered. If a cluster with vm's name, that means the vm is already registered

@param name the name of the virtual machine to be registered
@param parent the parent service provider

@return service_provider

=end classdoc

=cut

sub registerVm {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['parent', 'name', 'uuid']);

    my $hosting_hypervisor = $args{parent};
    my $vm_uuid            = $args{uuid};
    my $sp_renamed         = $self->_formatName(name => $args{name}, type => 'cluster');
    my $node_renamed       = $self->_formatName(name => $args{name}, type => 'node');

    #Get the hypervisor view
    my $hypervisor_view = $self->findEntityView(
                              view_type   => 'HostSystem',
                              hash_filter => {
                                  'hardware.systemInfo.uuid' => $hosting_hypervisor->vsphere5_uuid,
                              }
                          );

    #get the VM view from vSphere
    my $vm_view = $self->findEntityView(
                      view_type    => 'VirtualMachine',
                      hash_filter  => {
                          'config.uuid' => $vm_uuid,
                      },
                      begin_entity => $hypervisor_view,
                  );

    # one cluster created by vm registered
    my $service_provider;
    eval {
        $service_provider = Entity::ServiceProvider::Cluster->find(hash => {
                                         cluster_name => $sp_renamed,});
    };
    if ($@) {
        # connected state : the fact that host is available or not for management
        # power state will be managed by state-manager
        my $host_state = $vm_view->runtime->connectionState->val eq 'connected'
                             ? 'up' : 'broken';
        eval {
            my $admin_user = Entity::User->find(hash => { user_login => 'admin' });

            $service_provider = Entity::ServiceProvider::Cluster->new(
                active                 => 1,
                cluster_name           => $sp_renamed,
                cluster_state          => $host_state eq 'up' ? 'up:' . time() : 'down:' . time(),
                cluster_min_node       => 1,
                cluster_max_node       => 1,
                cluster_priority       => 500,
                cluster_si_shared      => 0,
                cluster_si_persistent  => 1,
                cluster_domainname     => 'my.domain',
                cluster_basehostname   => 'vsphere-service-' . $vm_view->summary->vm->value,
                cluster_nameserver1    => '127.0.0.1',
                cluster_nameserver2    => '127.0.0.1',
                cluster_boot_policy    => '',
                user_id                => $admin_user->user_id,
            );

            # policy and service template
            my $st = $self->_registerTemplate(
                policy_name  => 'vsphere_vm_policy',
                service_name => 'vSphere registered VMs'
            );
            $service_provider->applyPolicies(pattern => { 'service_template_id' => $st->id });

            # Now set this manager as host manager for the new service provider
            $service_provider->addManager(
                manager_type => 'HostManager',
                manager_id   => $self->id
            );

            # add default execution manager
            $self->_addExecutionManager(cluster => $service_provider);
        };
        if ($@) {
            $errmsg = 'Could not create new service provider to register vsphere vm: '. $@;
            throw Kanopya::Exception::Internal(error => $errmsg);
        }

        my $vm = Entity::Host->new(
                     host_manager_id    => $self->id,
                     host_serial_number => '',
                     host_desc          => $hypervisor_view->name . ' vm',
                     active             => 1,
                     host_ram           => $vm_view->config->hardware->memoryMB * 1024 * 1024,
                     host_core          => $vm_view->config->hardware->numCPU,
                     host_state         => $host_state . ':' . time(),
                 );

        # TODO : register MAC addresses

        #promote new virtual machine class to a vsphere5Vm one
        $self->promoteVm(
            host          => $vm,
            vm_uuid       => $vm_uuid,
            hypervisor_id => $hosting_hypervisor->id,
            guest_id      => $vm_view->config->guestId,
        );

        # Register the node
        $service_provider->registerNode(
            host     => $vm,
            hostname => $node_renamed,
            number   => 1,
            state    => 'in'
        );

        return $service_provider;
    }
    else {
        $errmsg  = 'VM already registered';
        $log->info($errmsg);

        return $service_provider;
    }
}

=pod

=begin classdoc

Register a new host to match a vsphere hypervisor
Check if a matching service provider already exist in Kanopya and, if so, return it
instead of creating a new one

@param name the name of the hypervisor to be registered
@param parent the parent of the hypervisor (must be a Vsphere5Datacenter object)

@return service_provider

=end classdoc

=cut

sub registerHypervisor {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['parent','name', 'uuid']);

    my $datacenter   = $args{parent};
    my $dc_name      = $datacenter->vsphere5_datacenter_name;
    my $node_renamed = $self->_formatName(name => $args{name}, type => 'node');
    my $hv_uuid      = $args{uuid};

    my $datacenter_view = $self->findEntityView(
                              view_type   => 'Datacenter',
                              hash_filter => {
                                  name => $dc_name
                              }
                          );
    my $hypervisor_view = $self->findEntityView(
                              view_type    => 'HostSystem',
                              hash_filter  => {
                                  'hardware.systemInfo.uuid' => $hv_uuid,
                              },
                              begin_entity => $datacenter_view,
                          );

    my $admin_user           = Entity::User->find(hash => { user_login => 'admin' });

    my $service_provider = $self->service_provider;

    # Now set this manager as host manager for service provider (if not yet done)
    eval {
        $service_provider->getHostManager();
    };
    if ($@) {
        $service_provider->addManager(
            manager_type => 'HostManager',
            manager_id   => $self->id
        );
    }

    # connected state : the fact that host is available or not for management
    # power state will be managed by state-manager
    my $host_state = $hypervisor_view->runtime->connectionState->val eq 'connected'
                         ? 'up' : 'broken';

    my $hv = Entity::Host->new(
                 host_manager_id    => $self->id,
                 host_serial_number => '',
                 host_desc          => $dc_name . ' hypervisor',
                 active             => 1,
                 host_ram           => $hypervisor_view->hardware->memorySize,
                 host_core          => $hypervisor_view->hardware->cpuInfo->numCpuCores,
                 host_state         => $host_state . ':' . time(),
             );

    # TODO : register MAC addresses

    # promote new hypervisor class to a vsphere5Hypervisor one
    my $vsphere_hyp = $self->addHypervisor(
                          host => $hv,
                          datacenter_id => $datacenter->id,
                          uuid => $hv_uuid
                      );

    # Register the node
    $service_provider->registerNode(
        host => $hv,
        hostname => $node_renamed,
        number   => 1,
        state    => 'in'
    );

    # TODO : state management + concurrent access
    my ($sp_state, $sp_timestamp) = $service_provider->getState;
    if ($host_state eq 'up' && $sp_state eq 'down') {
        $service_provider->setState(state => 'up');
    }

    return $vsphere_hyp;
}

=pod

=begin classdoc

Allow registering of hypervisors of a vsphere Cluster

@param name the name of the cluster to be registered
@param parent the parent of the cluster (must be a Vsphere5Datacenter object)

@return service_provider

=end classdoc

=cut

sub registerCluster {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['parent','name']);

    # we return datacenter since vsphere's cluster is not registered in Kanopya
    return $args{parent};
}

=head2 scaleHost

    Desc: launch a scale workflow that can be of type 'cpu' or 'memory'
    Args: $host_id, $scalein_value, $scalein_type

=cut

sub scaleHost {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host_id', 'scalein_value', 'scalein_type' ]);

    # vsphere requires memory value to be a multiple of 128 Mb
    if ($args{scalein_type} eq 'memory') {
        $args{scalein_value} -= $args{scalein_value} % (128 * 1024 * 1024);
    }

    $self->SUPER::scaleHost(%args);
}

=head generateMacAddress

class method
return a mac address auto generated and not used by any host

=cut

sub generateMacAddress {
    my ($self) = @_;

    return $self->SUPER::generateMacAddress(
        regexp => '00:50:56:[0-3]{1}[a-f0-9]{1}:[a-f0-9]{2}:[a-f0-9]{2}'
    );
}

=pod

=begin classdoc

Return the list of hypervisors managed by the component

@return \@hypervisors

=end classdoc

=cut

sub hypervisors {
    my $self = shift;

    my @hypervisors = Entity::Host::Hypervisor::Vsphere5Hypervisor->search(
                          hash => { vsphere5_id => $self->id }
                      );

    return \@hypervisors;
}

=pod

=begin classdoc

Register a new repository in kanopya for vSphere usage

@param repository_name the name of the datastore
@param container_access the Kanopya container access object associated to the datastore

@return $repository

=end classdoc

=cut

sub addRepository {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'container_access' ]);

    return Entity::Repository::Vsphere5Repository->new(
               virtualization_id   => $self->id,
               repository_name     => $args{container_access}->container->container_name,
               container_access_id => $args{container_access}->id,
           );
}

=pod

=begin classdoc

Get one or all the datacenters attached to this vsphere component

@optional datacenter_name the name of a specific datacenter to be retrieved

@return $datacenters

=end classdoc

=cut

sub getDatacenters {
    my ($self,%args) = @_;

    my $datacenters;

    if (defined $args{datacenter_name}) {
        $datacenters  = Entity::Component::Vsphere5::Vsphere5Datacenter->find(
                            hash => {
                                vsphere5_id              => $self->id,
                                vsphere5_datacenter_name => $args{datacenter_name},
                            }
                        );
    }
    else {
        $datacenters  = Entity::Component::Vsphere5::Vsphere5Datacenter->search(
                               hash => { vsphere5_id => $self->id }
                        );
    }

    return $datacenters;
}

=pod

=begin classdoc

Get a repository corresponding to a container access

@param container_access_id the container access id associated to the repository to be retrieved

@return $repository

=end classdoc

=cut

sub getRepository {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'container_access_id' ] );

    my $repository = Entity::Repository::Vsphere5Repository->find(hash => {
                         container_access_id => $args{container_access_id} }
                     );

    if (! defined $repository) {
        throw Kanopya::Exception::Internal(error => "No repository configured for Vsphere  " .$self->id);
    }

    return $repository;
}

=pod

=begin classdoc

Promote a virtual machine object to a Vsphere5Vm one

@param host the virtual machine host object to be promoted
@param guest_id the vmware guest id of the vm
@param hypervisor_id id of hypervisor hosting vm

@return vsphere5vm the promoted virtual machine

=end classdoc

=cut

sub promoteVm {
    my ($self, %args) = @_;

    General::checkParams(args => \%args,
                         required => [ 'host', 'vm_uuid', 'hypervisor_id' ],
                         optional => { 'guest_id' => 'debian6_64Guest' });

    $args{host} = Entity::Host::VirtualMachine::Vsphere5Vm->promote(
                      promoted           => $args{host},
                      vsphere5_id        => $self->id,
                      vsphere5_uuid      => $args{vm_uuid},
                      vsphere5_guest_id  => $args{guest_id},
                  );

    $args{host}->hypervisor_id($args{hypervisor_id});
    return $args{host};
}

=pod

=begin classdoc

Add default execution manager to a cluster

@param cluster the cluster on which manager will be added

=end classdoc

=cut

sub _addExecutionManager {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'cluster' ]);

    my $service_provider = $args{cluster};

    # Find the kanopya cluster
    my $kanopya = $service_provider->getKanopyaCluster();

    # Add default execution manager
    my $execution_manager = $kanopya->getComponent(name => "KanopyaExecutor");

    $service_provider->addManager(
        manager_id   => $execution_manager->id,
        manager_type => "ExecutionManager"
    );
}

sub _registerTemplate {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'policy_name', 'service_name' ]);

    my $hp_hash = { policy_name => $args{policy_name}, policy_type => 'hosting_policy' };

    # policy
    my $hp;
    eval {
        $hp = Entity::Policy->find(hash => $hp_hash);
    };
    if ($@) {
        $hp = Entity::Policy->new(%$hp_hash);
    }

    # service template
    my $st;
    eval {
        $st = Entity::ServiceTemplate->find(hash => { service_name => $args{service_name} });
    };
    if ($@) {
        $st = Entity::ServiceTemplate->new(
                  service_name      => $args{service_name},
                  hosting_policy_id => $hp->id,
              );
    }

    return $st;
}

=pod

=begin classdoc

Promote an Hypervisor class into a Vsphere5Hypervisor one

@param host the hypervisor class to be promoted
@param datacenter_id the id of the hypervisor's datacenter

@return vsphere5Hypervisor the promoted hypervisor

=end classdoc

=cut

sub addHypervisor {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'datacenter_id', 'uuid' ]);

    return Entity::Host::Hypervisor::Vsphere5Hypervisor->promote(
                                 promoted               => $args{host},
                                 vsphere5_id            => $self->id,
                                 vsphere5_datacenter_id => $args{datacenter_id},
                                 vsphere5_uuid          => $args{uuid},
           );
}

=pod

=begin classdoc

Return a list of active hypervisors ruled by this manager

@return active_hypervisors

=end classdoc

=cut

sub activeHypervisors {
    my $self = shift;

    my @hypervisors = $self->searchRelated(
                          filters => [ 'vsphere5_hypervisors' ],
                          hash    => { active => 1 }
                      );

    return wantarray ? @hypervisors : \@hypervisors;
}

=pod

=begin classdoc

Format a name that will be used for cluster and nodes creation

=end classdoc

=cut

sub _formatName {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'name', 'type' ]);

    my $name = $args{name};
    if ($args{type} eq 'cluster') {
        ($name = $args{name}) =~ s/[^A-Za-z0-9-]/-/g;
    }
    elsif ($args{type} eq 'node') {
        ($name = $args{name}) =~ s/[^\w\d\-\.]/-/g;
    }

    return $name;
}

=pod

=begin classdoc

override DESTROY to disconnect any open session toward a vSphere instance

=end classdoc

=cut

sub DESTROY {
    my $self = shift;

    $self->disconnect();
}

1;
