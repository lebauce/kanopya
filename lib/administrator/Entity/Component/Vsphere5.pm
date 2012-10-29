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
use Entity::User;
use Entity::Policy;
use Entity::ServiceTemplate;
use Entity::Operation;
use Entity::ServiceProvider::Inside::Cluster;
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
        'retrieveDatacenters'            =>  {
            'description'   =>  'Retrieve a list of Datacenters',
            'perm_holder'   =>  'entity',
        },
        'retrieveClustersAndHypervisors' =>  {
            'description'   =>  'Retrieve a list of Clusters and Hypervisors (that are not in a cluster) registered in a Datacenter',
            'perm_holder'   =>  'entity',
        },
        'retrieveClusterHypervisors'     =>  {
            'description'   =>  'Retrieve a list of Hypervisors that are registered in a Cluster',
            'perm_holder'   =>  'entity',
        },
        'retrieveClusterVms'             =>  {
            'description'   =>  'Retrieve a list of vms registered in a Cluster\'s hypervisor',
            'perm_holder'   =>  'entity',
        },
        'retrieveHypervisorVms'          =>  {
            'description'   =>  'Retrieve a list of vms registered under a vsphere hypervisor',
            'perm_holder'   =>  'entity',
        },
        'register'                       =>  {
            'description'   =>  'Register a new item with the vsphere component',
            'perm_holder'   =>  'entity',
        },
    };
}

=head2 checkHostManagerParams

=cut

sub checkHostManagerParams {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['ram', 'cpu']);
}

######################
# connection methods #
######################

=head2 connect

    Desc: Connect to a vCenter instance
    Args: $login, $pwd, $url
 
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
        print "a session to vSphere has been closed\n";
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
        $view = Vim::find_entity_view(view_type => 'Folder',
                                      filter    => {name => 'rootFolder'});
    };
    if ($@ =~ /no global session is defined/) {
        $log->info('opening a new session to vSphere');

        $self->connect(
            user_name => $self->vsphere5_login,
            password  => $self->vsphere5_pwd,
            url       => 'https://'.$self->vsphere5_url,
        );
        return;
    }
    else {
        $log->info('A session toward vSphere is already opened');
        return;
    }
}

####################
# Retrieve methods #
####################

=head2 retrieveDatacenters

    Desc: Retrieve list of all Datacenters
    Args: null
    Return: \@datacenter_infos

=cut

sub retrieveDatacenters {
    my ($self) = @_;

    my @datacenters_infos;

    my $datacenter_views = $self->findEntityViews(
                               view_type      => 'Datacenter',
                               array_property => ['name'],
                           );

    foreach my $datacenter_view (@$datacenter_views) {
        my %datacenter_infos = (
            name => $datacenter_view->name,
            type => 'datacenter',
         );
        push @datacenters_infos, \%datacenter_infos;
    }

    return \@datacenters_infos;
}

=head2 retrieveClustersAndHypervisors

    Desc: Retrieve list of Clusters and Hypervisors (that are not in a cluster)
          hosted in a given Datacenter
    Args: $datacenter_name
    Return: \@clusters_and_hypervisors_infos

=cut

sub retrieveClustersAndHypervisors {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['datacenter_name']);

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
                type => 'cluster'
            };
        }
        elsif(ref ($child_view) eq 'ComputeResource') {
            $compute_resource_infos = {
                name => $child_view->name,
                type => 'hypervisor'
            };
        }
        else {
            next CHILD;
        }

        push @clusters_hypervisors_infos, $compute_resource_infos;
    }

    return \@clusters_hypervisors_infos;
}

=head2 retrieveClusterHypervisors

    Desc: Retrieve a cluster's hypervisors
    Args: $cluster_name, $datacenter_name
    Return: \@hypervisors_infos

=cut

sub retrieveClusterHypervisors {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['cluster_name', 'datacenter_name']);

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

    #retrieve the cluster's hypervisors
    my $hosts_mor  = $cluster_view->host;

    my @hypervisors_infos;

    foreach my $hypervisor (@$hosts_mor) {
        my $hypervisor_view  = $self->getView(mo_ref => $hypervisor);
        my %hypervisor_infos = (
            name => $hypervisor_view->name,
            type => 'clusterHypervisor'
        );

        push @hypervisors_infos, \%hypervisor_infos;
    }

    return \@hypervisors_infos;
}

=head2 retrieveClusterVms

    Desc: Retrieve all the VM from a vsphere cluster hypervisor
    Args: $cluster_name, $datacenter_name, $hypervisor_name
    Return: \@vms_infos

=cut

sub retrieveClusterVms {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['cluster_name',
                                                      'datacenter_name',
                                                      'hypervisor_name']);

    #retrieve views
    my $datacenter_view = $self->findEntityView(
                              view_type   => 'Datacenter',
                              hash_filter => { name => $args{datacenter_name}},
                          );

    my $cluster_view    = $self->findEntityView(
                              view_type    => 'ClusterComputeResource',
                              hash_filter  => { name => $args{cluster_name}},
                              begin_entity => $datacenter_view,
                          );

    my $hypervisor_view = $self->findEntityView(
                              view_type    => 'HostSystem',
                              hash_filter  => { name => $args{hypervisor_name}},
                              begin_entity => $cluster_view,
                          );

    #get the vm
    my $vms_mor = $hypervisor_view->vm;

    my @vms_infos;

    foreach my $vm_mor (@$vms_mor) {
        my $vm = $self->getView(mo_ref => $vm_mor);
        my $vm_infos = {
            name => $vm->name,
            type => 'vm',
        };

        push @vms_infos, $vm_infos;
    }

    return \@vms_infos;
}

=head2 retrieveHypervisorVms

    Desc: Retrieve all the VM from a vsphere hypervisor
    Args: $datacenter_name, $hypervisor_name
    Return: \@vms_infos

=cut

sub retrieveHypervisorVms {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['datacenter_name', 'hypervisor_name']);

    #retrieve views
    my $datacenter_view = $self->findEntityView(
                              view_type   => 'Datacenter',
                              hash_filter => { name => $args{datacenter_name}},
                          );

    my $hypervisor_view = $self->findEntityView(
                              view_type    => 'HostSystem',
                              hash_filter  => { name => $args{hypervisor_name}},
                              begin_entity => $datacenter_view,
                          );

    #get the vm
    my $vms_mor = $hypervisor_view->vm;

    my @vms_infos;

    foreach my $vm_mor (@$vms_mor) {
        my $vm = $self->getView(mo_ref => $vm_mor);
        my $vm_infos = {
            name => $vm->name,
            type => 'vm',
        };

        push @vms_infos, $vm_infos;
    }

    return \@vms_infos;
}

###########################
# vsphere objects methods #
###########################

=head2 getView

    Desc: get a vsphere managed object view
    Args: $mo_ref (managed object reference)
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
          \%hash_filter, \@array_property, $begin_entity view
    Return: a managed entity view

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

=head2 findEntityViews

    Desc: find views of a specified managed object type
    Args: $view_type (HostSystem,VirtualMachine,Datacenter,Folder,ResourcePool,
                      ClusterComputeResource or ComputeResource),
          %hash_filter, @array_property, $begin_entity view
    Return: a list of managed entity views

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

##########################
## registration methods ##
##########################

#TODO: manage the possibility that the entities, for example clusters can be into vsphere
#folders

=head2 register

    Desc: register vSphere items into kanopya service providers
    Args: $register_items, objects to be registered into Kanopya
          $parent, the optional parent of this object
=cut

sub register {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['register_items'],
                                         optional => {
                                             parent => undef,
                                         });
    $self->negociateConnection();

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
                               );
        };
        if ($@) {
            $errmsg = 'Could not register '. $register_item->{name} .' in Kanopya: '. $@;
            $log->info($errmsg);
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

=head2 registerDatacenter

    Desc: register a new vsphere datacenter into Kanopya
          return the corresponding datacenter if it already exist
    Args: $name
    Return: $datacenter or $existing_datacenter
 
=cut 

sub registerDatacenter {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['name']);

    #First we check if the datacenter already exist in Kanopya
    my $existing_datacenter;
    eval {
        $existing_datacenter = Vsphere5Datacenter->find(hash => {
                                   vsphere5_datacenter_name => $args{name},
                                   vsphere5_id              => $self->id,
                               });
    };
    if (defined $existing_datacenter) {
        $errmsg  = 'The datacenter '. $args{name} .' already exist in kanopya ';
        $errmsg .= 'with ID '. $existing_datacenter->id;
        $errmsg .= ' and is already associated with this component (id '. $self->id .')';
        $log->info($errmsg);
        return $existing_datacenter;
    }
    else {
        my $datacenter;
        eval {
            $datacenter = Vsphere5Datacenter->new(
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
}

=head2 registerVm

    Desc: register a new virtual machine to match a vsphere vm
    Args: $name, $parent (a service provider)
    Return: $service_provider
 
=cut

sub registerVm {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['parent', 'name']);

    my $parent_service_provider     = $args{parent};
    my $service_provider_name       = $args{name};
    #We substitute terms in (new string) to match cluster_name pattern
    (my $service_provider_renamed   = $service_provider_name) =~ s/[^\w\d+]/_/g;

    #Get the datacenter used by the hosting hypervisor(s)
    my @hypervisors_nodes;
    eval {
        @hypervisors_nodes = Externalnode::Node->search(hash => {
                                 inside_id => $parent_service_provider->id});
    };
    if ($@) {
        $errmsg  = 'Could not find any node in the parent service provider: '. $@;
        $errmsg .= 'Has the parent service provider been correctly registered?';
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    #use the first hypervisor in the list
    my $datacenter      = $hypervisors_nodes[0]->host->vsphere5_datacenter;
    my $datacenter_name = $datacenter->vsphere5_datacenter_name;

    #Get the datacenter view
    my $datacenter_view = $self->findEntityView(
                              view_type   => 'Datacenter',
                              hash_filter => {
                                  name => $datacenter_name
                              }
                          );

    #get the VM view from vSphere
    my $vm_view = $self->findEntityView(
                      view_type    => 'VirtualMachine',
                      hash_filter  => {
                          name => $service_provider_name,
                      },
                      begin_entity => $datacenter_view,
                  );

    #Check if a service provider called $service_provider_name already exist and
    #Create a new one to hold the vsphere vm if none exists
    my $service_provider;

    eval {
        $service_provider = Entity::ServiceProvider::Inside::Cluster->find(hash => {
                                         cluster_name => $service_provider_renamed,});
    };
    if (defined $service_provider) {
        $errmsg  = 'vSphere component will not create new service provider for the vm ';
        $errmsg .= $service_provider_renamed. ' because this name already exist in kanopya';
        $log->info($errmsg);
        return $service_provider;
    }
    else {
        eval {
            my $admin_user = Entity::User->find(hash => { user_login => 'admin' });

            $service_provider = Entity::ServiceProvider::Inside::Cluster->new(
                                    active                 => 1,
                                    cluster_name           => $service_provider_renamed,
                                    cluster_state          => 'up:'. time(),
                                    cluster_min_node       => 1,
                                    cluster_max_node       => 1,
                                    cluster_priority       => 500,
                                    cluster_si_shared      => 0,
                                    cluster_si_persistent  => 1,
                                    cluster_domainname     => 'my.domain',
                                    cluster_basehostname   => 'vsphere_service_'. $vm_view->summary->vm->value,
                                    cluster_nameserver1    => '127.0.0.1',
                                    cluster_nameserver2    => '127.0.0.1',
                                    cluster_boot_policy    => '',
                                    user_id                => $admin_user->user_id,
                                );

            #Check if the vsphere hosting policy and the vsphere vm policy already exist
            #If not create them 
            my $hp;
            my $st;

            eval {
                $hp = Entity::Policy->find(hash => {
                          policy_name => 'vsphere'}
                      );
            };
            if (not defined $hp) {
                $hp = Entity::Policy->new(
                         policy_type => 'hosting_policy',
                         policy_name => 'vsphere',
                      );
            }

            eval {
                $st = Entity::ServiceTemplate->find(hash => {
                          hosting_policy_id => $hp->id,
                          service_name      => 'vsphere_vm_service',}
                      );
            };
            if (defined $st) {
                $service_provider->setAttr(name  => 'service_template_id',
                                           value => $st->id);
                $service_provider->save();
            }
            else {
                $st = Entity::ServiceTemplate->new(
                          hosting_policy_id => $hp->id,
                          service_name      => 'vsphere_vm_service'
                      );
                $service_provider->setAttr(name  => 'service_template_id',
                                           value => $st->id);
                $service_provider->save();
            }
        };
        if ($@) {
            print $@;
            $errmsg = 'Could not create new service provider to register vsphere vm: '. $@;
            throw Kanopya::Exception::Internal(error => $errmsg);
        }

        #Resolve which hypervisor in the parent service provider is hosting the VM
        #1) if the parent is a single hypervisor, get it's id directly
        #2) if the parent is a cluster, loop into the hypervisor's list, retrieve it's view from
        #Vsphere, and check if it is hosting the vm
        my $hosting_hypervisor_id;
        if (scalar (@hypervisors_nodes) == 1) {
            $hosting_hypervisor_id = $hypervisors_nodes[0]->host->id;
        }
        else {
            HOSTING_HYPERVISOR:
            foreach my $hypervisor_node (@hypervisors_nodes) {
                my $hypervisor_view = $self->findEntityView(
                                          view_type    => 'HostSystem',
                                          hash_filter  => {
                                                name => $hypervisor_node->host->host_hostname,
                                          },
                                          begin_entity => $datacenter_view,
                                      );
                my @vms = $hypervisor_view->vm;
                foreach my $vm (@vms) {
                    my $view = $self->getView(mo_ref => $vm);
                    if ($view->name eq $vm_view->name) {
                        $hosting_hypervisor_id = $hypervisor_node->host->id;
                        last HOSTING_HYPERVISOR;
                    }
                }
            }
        }

        # Use the first kernel found...
        my $kernel = Entity::Kernel->find(hash => {});

        my $host_state;
        my $time;

        #we define the state time as now
        if ($vm_view->runtime->connectionState->val    eq 'disconnected') {
            $time       = time();
            $host_state = 'down: '. $time;
        }
        elsif ($vm_view->runtime->connectionState->val eq 'connected') {
            $time       = time();
            $host_state = 'up: '. $time;
        }
        elsif ($vm_view->runtime->connectionState->val eq 'inaccessible') {
            $time       = time();
            $host_state = 'broken: '. $time;
        }

        my $vm = Entity::Host::VirtualMachine->new(
                     host_manager_id    => $self->id,
                     kernel_id          => $kernel->id,
                     host_serial_number => '',
                     host_desc          => $datacenter_name. ' vm',
                     active             => 1,
                     host_ram           => $vm_view->summary->config->memorySizeMB * 1024 * 1024,
                     host_core          => $vm_view->summary->config->numCpu,
                     host_hostname      => $service_provider_renamed,
                     host_state         => $host_state,
                     hypervisor_id      => $hosting_hypervisor_id,
                 );

        #promote new virtual machine class to a vsphere5Vm one
        $self->addVM(host => $vm, guest_id => $vm_view->summary->config->guestId);

        my $node = Externalnode::Node->new(
                       inside_id             => $service_provider->id,
                       host_id               => $vm->id,
                       master_node           => 1,
                       node_number           => 1,
                       node_state            => 'in:'.$time,
                       externalnode_hostname => $vm_view->name,
                   );

        return $service_provider;
    }
}

=head2 registerHypervisor

    Desc: register a new host to match a vsphere hypervisor
    Args: $name, $parent (datacenter)
    Return: $service_provider
 
=cut

sub registerHypervisor {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['parent','name']);

    #If parent is not a datacenter, exit, returning the parent
    if (!(ref $args{parent} eq 'Vsphere5Datacenter')) {
        my $msg = 'Can\'t register a hypervisor with this method without a datacenter parent';
        $log->info($msg);
        return $args{parent};
    }

    my $datacenter                  = $args{parent};
    my $service_provider_name       = $args{name};
    #We substitute terms in (new string) to match cluster_name pattern
    (my $service_provider_renamed   = $service_provider_name) =~ s/[^\w\d\.+]/_/g;
    my $datacenter_name             = $datacenter->vsphere5_datacenter_name;

    #Get the datacenter view
    my $datacenter_view = $self->findEntityView(
                              view_type   => 'Datacenter',
                              hash_filter => {
                                  name => $datacenter_name
                              }
                          );

    #Get hypervisor's view
    my $hypervisor_view = $self->findEntityView(
                              view_type    => 'HostSystem',
                              hash_filter  => {
                                  name => $service_provider_name,
                              },
                              begin_entity => $datacenter_view,
                          );

    #Check if a service provider called $service_provider_name already exist and
    #Create a new one to hold the vsphere cluster hypervisors if none exists
    my $service_provider;

    eval {
        $service_provider = Entity::ServiceProvider::Inside::Cluster->find(hash => {
                                         cluster_name => $service_provider_renamed,}
                                     );
    };
    if (defined $service_provider) {
        $errmsg  = 'vSphere component will not create new service provider for hypervisor ';
        $errmsg .= $service_provider_renamed. ' because this name already exist in kanopya';
        $log->info($errmsg);
        return $service_provider;
    }
    else {
        eval {
            my $admin_user           = Entity::User->find(hash => { user_login => 'admin' });
            my $cluster_basehostname = 'vsphere_service_'. $hypervisor_view->summary->host->value;

            $service_provider = Entity::ServiceProvider::Inside::Cluster->new(
                                    active                 => 1,
                                    cluster_name           => $service_provider_renamed,
                                    cluster_state          => 'up:'. time(),
                                    cluster_min_node       => 1,
                                    cluster_max_node       => 1,
                                    cluster_priority       => 500,
                                    cluster_si_shared      => 0,
                                    cluster_si_persistent  => 1,
                                    cluster_domainname     => 'my.domain',
                                    cluster_basehostname   => $cluster_basehostname,
                                    cluster_nameserver1    => '127.0.0.1',
                                    cluster_nameserver2    => '127.0.0.1',
                                    cluster_boot_policy    => '',
                                    user_id                => $admin_user->user_id,
                                );

            #Check if the vsphere hosting policy and the vsphere hypervisor policy already exist
            #If not create them 
            my $hp;
            my $st;

            eval {
                $hp = Entity::Policy->find(hash => {
                          policy_name => 'vsphere'}
                      );
            };
            if (not defined $hp) {
                $hp = Entity::Policy->new(
                         policy_type => 'hosting_policy',
                         policy_name => 'vsphere'
                      );
            }

            eval {
                $st = Entity::ServiceTemplate->find(hash => {
                          hosting_policy_id => $hp->id,
                          service_name      => 'vsphere_hypervisor_service',}
                      );
            };
            if (defined $st) {
                $service_provider->setAttr(name  => 'service_template_id',
                                           value => $st->id);
                $service_provider->save();
            }
            else {
                $st = Entity::ServiceTemplate->new(
                          hosting_policy_id => $hp->id,
                          service_name      => 'vsphere_hypervisor_service'
                      );
                $service_provider->setAttr(name  => 'service_template_id',
                                           value => $st->id);
                $service_provider->save();
            }
        };
        if ($@) {
            $errmsg = 'Could not create new service provider to register vsphere hypervisor: '. $@;
            throw Kanopya::Exception::Internal(error => $errmsg);
        }

        # Use the first kernel found...
        my $kernel = Entity::Kernel->find(hash => {});

        my $host_state;
        my $time;

        #we define the state time as now
        if ($hypervisor_view->runtime->connectionState->val    eq 'disconnected') {
            $time       = time();
            $host_state = 'down: '. $time;
        }
        elsif ($hypervisor_view->runtime->connectionState->val eq 'connected') {
            $time       = time();
            $host_state = 'up: '. $time;
        }
        elsif ($hypervisor_view->runtime->connectionState->val eq 'notResponding') {
            $time       = time();
            $host_state = 'broken: '. $time;
        }

        my $hv = Entity::Host::Hypervisor->new(
                     host_manager_id    => $self->id,
                     kernel_id          => $kernel->id,
                     host_serial_number => '',
                     host_desc          => $datacenter_name. ' hypervisor',
                     active             => 1,
                     host_ram           => $hypervisor_view->hardware->memorySize,
                     host_core          => $hypervisor_view->summary->hardware->numCpuCores,
                     host_hostname      => $service_provider_renamed,
                     host_state         => $host_state,
                 );

        #promote new hypervisor class to a vsphere5Hypervisor one
        $self->addHypervisor(host => $hv, datacenter_id => $datacenter->id);

        my $node = Externalnode::Node->new(
                       inside_id             => $service_provider->id,
                       host_id               => $hv->id,
                       master_node           => 1,
                       node_number           => 1,
                       node_state            => 'in:'.$time,
                       externalnode_hostname => $hypervisor_view->name,
                   );

        return $service_provider;
    }
}

=head2 registerCluster

    Desc: register a new service provider with the content of a vsphere Cluster
    Args: $name, $parent
    Return: $service_provider
 
=cut

sub registerCluster {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['parent','name']);

    #If parent is not a datacenter, exit, returning the parent
    if (!(ref $args{parent} eq 'Vsphere5Datacenter')) {
        my $msg = 'Can\'t register a cluster with this method without a datacenter parent';
        $log->info($msg);
        return $args{parent};
    }

    my $datacenter          = $args{parent};
    my $datacenter_name     = $datacenter->vsphere5_datacenter_name;
    my $cluster_name        = $args{name};
    #We substitute terms in (new string) to match cluster_name pattern
    (my $cluster_renamed    = $cluster_name) =~ s/[^\w\d+]/_/g;

    #get Datacenter and Cluster views from vsphere
    my $datacenter_view  = $self->findEntityView(
                               view_type   => 'Datacenter',
                               hash_filter => {
                                   name => $datacenter_name,
                               }
                           );
    my $cluster_view     = $self->findEntityView(
                               view_type    => 'ClusterComputeResource',
                               hash_filter  => {
                                   name => $cluster_name
                               },
                               begin_entity => $datacenter_view,
                           );
    #Get the cluster's hypervisors
    my @hypervisors = @{ $cluster_view->host };

    #Check if a service provider called $cluster_name already exist and
    #Create a new one to hold the vsphere cluster hypervisors if none exists
    my $service_provider;

    eval {
        $service_provider = Entity::ServiceProvider::Inside::Cluster->find(hash => {
                                         cluster_name => $cluster_renamed,
                                     });
    };
    if (defined $service_provider) {
        $errmsg  = 'vSphere component will not create new service provider for cluster ';
        $errmsg .= $cluster_name. ' because one with the same name already exist in kanopya';
        $log->info($errmsg);
        return $service_provider;
    }
    else {
        eval {
            my $admin_user           = Entity::User->find(hash => { user_login => 'admin' });
            my $cluster_basehostname = 'vsphere_service_'. lc $cluster_renamed. '_' .time();

            $service_provider = Entity::ServiceProvider::Inside::Cluster->new(
                                    active                 => 1,
                                    cluster_name           => $cluster_renamed,
                                    cluster_state          => 'up:'. time(),
                                    cluster_min_node       => 1,
                                    cluster_max_node       => scalar(@hypervisors),
                                    cluster_priority       => 500,
                                    cluster_si_shared      => 0,
                                    cluster_si_persistent  => 1,
                                    cluster_domainname     => 'my.domain',
                                    cluster_basehostname   => $cluster_basehostname,
                                    cluster_nameserver1    => '127.0.0.1',
                                    cluster_nameserver2    => '127.0.0.1',
                                    cluster_boot_policy    => '',
                                    user_id                => $admin_user->user_id,
                                );
    
            #Check if the vsphere hosting policy and the vsphere vm policy already exist
            #If not create them 
            my $hp;
            my $st;

            eval {
                $hp = Entity::Policy->find(hash => {
                          policy_name => 'vsphere'}
                      );
            };
            if (not defined $hp) {
                $hp = Entity::Policy->new(
                         policy_type => 'hosting_policy',
                         policy_name => 'vsphere',
                      );
            }

            eval {
                $st = Entity::ServiceTemplate->find(hash => {
                          hosting_policy_id => $hp->id,
                          service_name      => 'vsphere_hypervisor_service'});
            };
            if (defined $st) {
                $service_provider->setAttr(name  => 'service_template_id',
                                           value => $st->id);
                $service_provider->save();
            }
            else {
                $st = Entity::ServiceTemplate->new(
                          hosting_policy_id => $hp->id,
                          service_name      => 'vsphere_hypervisor_service',
                      );
                $service_provider->setAttr(name  => 'service_template_id',
                                           value => $st->id);
                $service_provider->save();
            }
        };
        if ($@) {
            $errmsg = 'Could not create new service provider to register vsphere cluster: '. $@;
            throw Kanopya::Exception::Internal(error => $errmsg);
        }

        # Use the first kernel found...
        my $kernel = Entity::Kernel->find(hash => {});

        foreach my $hv_number (0..$#hypervisors) {
            my $hypervisor = $hypervisors[$hv_number];

            #Get hypervisor's view from it's MOR
            my $hypervisor_view = $self->getView(mo_ref => $hypervisor);
            my $host_state;
            my $time;

            #we define the state time as now
            if ($hypervisor_view->runtime->connectionState->val    eq 'disconnected') {
                $time = time();            
                $host_state = 'down: '.$time;
            }
            elsif ($hypervisor_view->runtime->connectionState->val eq 'connected') {
                $time = time();            
                $host_state = 'up: '.$time;
            }
            elsif ($hypervisor_view->runtime->connectionState->val eq 'notResponding') {
                $time = time();            
                $host_state = 'broken: '.$time;
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

            my $node = Externalnode::Node->new(
                           inside_id             => $service_provider->id,
                           host_id               => $hv->id,
                           master_node           => 0,
                           node_number           => $hv_number + 1,
                           node_state            => 'in:'.$time,
                           externalnode_hostname => $hypervisor_view->name,
                       );
        }

    return $service_provider;
    }
}

###########################
## configuration methods ##
## getters and setters   ##
###########################

=head 2 setConf

    Desc: Define the component configuration
    Args: \%conf

=cut

sub setConf {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['conf']);

    my $conf = $args{conf};

    if (defined $conf->{repositories}) {
        while (my ($repo,$container) = each (%{$conf->{repositories}})) {
            $self->addRepository(repository_name     => $repo,
                                 container_access_id => $container->{container_access_id});
        }
        delete $conf->{repositories};
    }

    $self->SUPER::setConf(conf => $conf);
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
    $conf{url}          = $self->vsphere5_url;
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
                            }
                        );
    }
    else {
        $datacenters  = Vsphere5Datacenter->search(
                               hash => { vsphere5_id => $self->id }
                        );
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

    Desc: promote an Host::Hypervior into a Kanopya vsphere hypervisor
    Args: $host,$datacenter_id
    Return: a new instance of vsphere5_hypervisor

=cut

sub addHypervisor {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'datacenter_id' ]);

    my $hypervisor_type = 'Entity::Host::Hypervisor::Vsphere5Hypervisor';

    return $hypervisor_type->promote(
               promoted               => $args{host},
               vsphere5_id            => $self->id,
               vsphere5_datacenter_id => $args{datacenter_id}
           );
}

1;
