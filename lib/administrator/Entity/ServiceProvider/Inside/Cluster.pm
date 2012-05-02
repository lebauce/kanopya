# Cluster.pm - This object allows to manipulate cluster configuration
#    Copyright 2011 Hedera Technology SAS
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
# Created 3 july 2010
package Entity::ServiceProvider::Inside::Cluster;
use base 'Entity::ServiceProvider::Inside';

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Component;
use Entity::Host;
use Entity::Systemimage;
use Entity::Tier;
use Operation;
use Administrator;
use General;
use Entity::ManagerParameter;

use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    cluster_name => {
        pattern      => '^\w*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_desc => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 1
    },
    cluster_type => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_boot_policy => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_si_shared => {
        pattern      => '^(0|1)$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_si_persistent => {
        pattern      => '^(0|1)$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_min_node => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    cluster_max_node => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    cluster_priority => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    cluster_state => {
        pattern      => '^up:\d*|down:\d*|starting:\d*|stopping:\d*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_domainname => {
        pattern      => '^[a-z0-9-]+(\.[a-z0-9-]+)+$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_nameserver1 => {
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_nameserver2 => {
        pattern      => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    cluster_basehostname => {
        pattern      => '^[a-z_]+$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    active => {
        pattern      => '^[01]$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    masterimage_id => {
        pattern      => '\d*',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    kernel_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 1
    },
	user_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    host_manager_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    disk_manager_id => {
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
    export_manager_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
    collector_manager_id => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'create'    => {'description' => 'create a new cluster',
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this cluster',
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this cluster',
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this cluster',
                        'perm_holder' => 'entity',
        },
        'addNode'    => {'description' => 'add a node to this cluster',
                        'perm_holder' => 'entity',
        },
        'removeNode'=> {'description' => 'remove a node from this cluster',
                        'perm_holder' => 'entity',
        },
        'activate'=> {'description' => 'activate this cluster',
                        'perm_holder' => 'entity',
        },
        'deactivate'=> {'description' => 'deactivate this cluster',
                        'perm_holder' => 'entity',
        },
        'start'=> {'description' => 'start this cluster',
                        'perm_holder' => 'entity',
        },
        'stop'=> {'description' => 'stop this cluster',
                        'perm_holder' => 'entity',
        },
        'forceStop'=> {'description' => 'force stop this cluster',
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this cluster',
                        'perm_holder' => 'entity',
        },
        'addComponent'    => {'description' => 'add a component to this cluster',
                        'perm_holder' => 'entity',
        },
        'removeComponent'    => {'description' => 'remove a component from this cluster',
                        'perm_holder' => 'entity',
        },
        'configureComponents'    => {'description' => 'configure components of this cluster',
                        'perm_holder' => 'entity',
        },
    };
}

=head2 getClusters

=cut

sub getClusters {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

sub getCluster {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    my @clusters = $class->search(%args);
    return pop @clusters;
}

=head2 create

=cut

sub create {
    my ($class, %params) = @_;

    my $admin = Administrator->new();
    my $mastergroup_eid = $class->getMasterGroupEid();
    my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $mastergroup_eid, method => 'create');
    if (not $granted) {
       throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new user");
    }

    # we remove specific managers parameters before attributes cheking 
    my %managers_params = ();
    for my $key (keys %params) {
        if($key =~ /(^host_manager_param|^disk_manager_param|^export_manager_param)/) {
           $managers_params{$key} = $params{$key};
           delete $params{$key};
        }
    }

    $class->checkAttrs(attrs => \%params);

    %params = (%params, %managers_params);

    $log->debug("New Operation Create with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'AddCluster',
        params   => \%params,
    );
}

=head2 update

=cut

sub update {
    my $self = shift;
    my $adm = Administrator->new();
    # update method concerns an existing entity so we use his entity_id
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'update');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to update this entity");
       }
    # TODO update implementation
}

=head2 remove

=cut

sub remove {
    my $self = shift;
    my $adm = Administrator->new();
    # delete method concerns an existing entity so we use his entity_id
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'delete');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to delete this entity");
       }
    my %params;
    $params{'cluster_id'}= $self->getAttr(name =>"cluster_id");
    $log->debug("New Operation Remove Cluster with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveCluster',
        params   => \%params,
    );
}

sub forceStop {
    my $self = shift;
    my $adm = Administrator->new();
    # delete method concerns an existing entity so we use his entity_id
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'forceStop');
    if (not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to force stop this entity");
    }
    my %params;
    $params{'cluster_id'} = $self->getAttr(name => "cluster_id");

    $log->debug("New Operation Force Stop Cluster with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'ForceStopCluster',
        params   => \%params,
    );
}

sub extension { return "clusterdetails"; }

sub activate {
    my $self = shift;

    $log->debug("New Operation ActivateCluster with cluster_id : " . $self->getAttr(name=>'cluster_id'));
    Operation->enqueue(priority => 200,
                   type     => 'ActivateCluster',
                   params   => {cluster_id => $self->getAttr(name=>'cluster_id')});
}

sub deactivate {
    my $self = shift;

    $log->debug("New Operation DeactivateCluster with cluster_id : " . $self->getAttr(name=>'cluster_id'));
    Operation->enqueue(priority => 200,
                   type     => 'DeactivateCluster',
                   params   => {cluster_id => $self->getAttr(name=>'cluster_id')});
}



sub getTiers {
    my $self = shift;
    
    my %tiers;
    my $rs_tiers = $self->{_dbix}->tiers;
    if (! defined $rs_tiers) {
        return;
    }
    else {
        my %tiers;
        while ( my $tier_row = $rs_tiers->next ) {
            my $tier_id = $tier_row->get_column("tier_id");
            $tiers{$tier_id} = Entity::Tier->get(id => $tier_id);
        }
    }
    return \%tiers;
}


=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('cluster_name');
    return $string.' (Cluster)';
}

=head2 getComponents

    Desc : This function get components used in a cluster. This function allows to select
            category of components or all of them.
    args:
        administrator : Administrator : Administrator object to instanciate all components
        category : String : Component category
    return : a hashref of components, it is indexed on component_instance_id

=cut

sub getComponents {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['category']);

    my $components_rs = $self->{_dbix}->parent->search_related("components", undef,
		{ '+columns' => { "component_name"     => "component_type.component_name",
						  "component_version"  => "component_type.component_version",
						  "component_category" => "component_type.component_category"},
	   join => ["component_type"]}
	);

    my %comps;
    $log->debug("Category is $args{category}");
    while ( my $component_row = $components_rs->next ) {
        my $comp_id           = $component_row->get_column('component_id');
        my $comptype_category = $component_row->get_column('component_category');
        my $comptype_name     = $component_row->get_column('component_name');
        my $comptype_version  = $component_row->get_column('component_version');
        
        $log->debug("Component name: $comptype_name");
        $log->debug("Component version: $comptype_version");
        $log->debug("Component category: $comptype_category");
        $log->debug("Component id: $comp_id");
        
        if (($args{category} eq "all")||
            ($args{category} eq $comptype_category)){
            $log->debug("One component instance found with " . ref($component_row));
            my $class= "Entity::Component::" . $comptype_name . $comptype_version;
            my $loc = General::getLocFromClass(entityclass=>$class);
            eval { require $loc; };
            $comps{$comp_id} = $class->get(id =>$comp_id);
        }
    }
    return \%comps;
}

=head2 getComponent

    Desc : This function get component used in a cluster. This function allows to select
            a particular component with its name and version.
    args:
        administrator : Administrator : Administrator object to instanciate all components
        name : String : Component name
        version : String : Component version
    return : a component instance

=cut

sub getComponent{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['name','version']);

    my $hash = {
        'component_type.component_name'    => $args{name},
        'component_type.component_version' => $args{version}
    };

    my $component_row;
    eval {
        my $components_rs = $self->{_dbix}->parent->search_related(
                                "components", $hash,
                                { "+columns" =>
                                    { "component_name"     => "component_type.component_name",
                                      "component_version"  => "component_type.component_version",
                                      "component_category" => "component_type.component_category" },
                                  join => [ "component_type" ] }
                            );

        $log->debug("Name is $args{name}, version is $args{version}");

        $component_row = $components_rs->next;
    };
    if (not defined $component_row or $@) {
        throw Kanopya::Exception::Internal(
                  error => "Component with name <$args{name}>, version <$args{version}> " .
                           "not installed on this cluster:\n$@"
              );
    }

    $log->debug("Comp name is " . $component_row->get_column('component_name'));
    $log->debug("Component found with " . ref($component_row));

    my $comp_category = $component_row->get_column('component_category');
    my $comp_id       = $component_row->id;
    my $comp_name     = $component_row->get_column('component_name');
    my $comp_version  = $component_row->get_column('component_version');

    my $class= "Entity::Component::" . $comp_name . $comp_version;
    my $loc = General::getLocFromClass(entityclass => $class);

    eval { require $loc; };
    if ($@) {
        throw Kanopya::Exception::Internal::UnknownClass(error => "Could not find $loc :\n$@");
    }
    return "$class"->get(id => $comp_id);
}

sub getComponentByInstanceId{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['component_instance_id']);

    my $hash = {'component_instance_id' => $args{component_instance_id}};
    my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", $hash,
                                            { '+columns' => {"component_name" => "component.component_name",
                                                            "component_version" => "component.component_version",
                                                            "component_category" => "component.component_category"},
                                                    join => ["component"]});

    my $comp_instance_row = $comp_instance_rs->next;
    if (not defined $comp_instance_row) {
        throw Kanopya::Exception::Internal(error => "Component with component_instance_id '$args{component_instance_id}' not found on this cluster");
    }
    $log->debug("Comp name is " . $comp_instance_row->get_column('component_name'));
    $log->debug("Component instance found with " . ref($comp_instance_row));
    my $comp_category = $comp_instance_row->get_column('component_category');
    my $comp_instance_id = $comp_instance_row->get_column('component_instance_id');
    my $comp_name = $comp_instance_row->get_column('component_name');
    my $comp_version = $comp_instance_row->get_column('component_version');
    my $class= "Entity::Component::" . $comp_name . $comp_version;
    my $loc = General::getLocFromClass(entityclass=>$class);
    eval { require $loc; };
    return "$class"->get(id =>$comp_instance_id);
}

sub getMasterNode {
    my $self = shift;
    my $node_instance_rs = $self->{_dbix}->parent->search_related(
                               "nodes", { master_node => 1 }
                           )->single;

    if(defined $node_instance_rs) {
        my $host = { _dbix => $node_instance_rs->host };
        bless $host, "Entity::Host";
        return $host;
    } else {
        $log->debug("No Master node found for this cluster");
        return;
    }
}

sub getMasterNodeIp {
    my $self = shift;
    my $master = $self->getMasterNode();

    if ($master) {
        my $node_ip = $master->getAdminIp;

        $log->debug("Master node found and its ip is $node_ip");
        return $node_ip;
    }
}

sub getMasterNodeId {
    my $self = shift;
    my $host = $self->getMasterNode;

    if (defined ($host)) {
        return $host->getAttr(name => "host_id");
    }
}

sub getMasterNodeSystemimage {
    my $self = shift;
    my $node_instance_rs = $self->{_dbix}->parent->search_related(
                               "nodes", { master_node => 1 }
                           )->single;

    if(defined $node_instance_rs) {
        return Entity::Systemimage->get(id => $node_instance_rs->get_column('systemimage_id'));
    }
}

=head2 addComponent

link a existing component with the cluster

=cut

sub addComponent {
    my $self = shift;
    my %args = @_;
    my $noconf;

    General::checkParams(args => \%args, required => ['component']);

    my $component = $args{component};
    $component->setAttr(name  => 'service_provider_id',
                        value => $self->getAttr(name => 'cluster_id'));
    $component->save();

    return $component->{_dbix}->id;
}

=head2 addComponentFromType

create a new componant and link it to the cluster 

=cut

sub addComponentFromType {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['component_type_id']);
	my $type_id = $args{component_type_id};
	my $adm = Administrator->new();
	my $row = $adm->{db}->resultset('ComponentType')->find($type_id);
	my $comp_name = $row->get_column('component_name');	
	my $comp_version = $row->get_column('component_version');
	my $comp_class = 'Entity::Component::'.$comp_name.$comp_version;
	my $location = General::getLocFromClass(entityclass => $comp_class);
	eval {require $location };
	my $component = $comp_class->new();
	$component->setAttr(name  => 'service_provider_id',
	                    value => $self->getAttr(name => 'cluster_id'));
	$component->save();

    return $component->{_dbix}->id;
}

=head2 removeComponent

remove a component instance and all its configuration
from this cluster

=cut

sub removeComponent {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['component_instance_id']);

    my $component_instance = Entity::Component->get(id => $args{component_instance_id});
    $component_instance->delete;
}

=head2 getHosts

    Desc : This function get hosts executing the cluster.
    args:
        administrator : Administrator : Administrator object to instanciate all components
    return : a hashref of host, it is indexed on host_id

=cut

sub getHosts {
    my $self = shift;

    my %hosts;
    eval {
        my $host_rs = $self->{_dbix}->parent->nodes;
        while (my $node_row = $host_rs->next) {
            my $host_row = $node_row->host;
            $log->debug("Nodes found");
            my $host_id = $host_row->get_column('host_id');
            eval {
                $hosts{$host_id} = Entity::Host->get(id => $host_id);
            };
        }
    };
    if ($@) {
        throw Kanopya::Exception::Internal(
                  error => "Could not get cluster nodes:\n$@"
              );
    }
    return \%hosts;
}

=head2 getCurrentNodesCount

    class : public
    desc : return the current nodes count of the cluster

=cut

sub getCurrentNodesCount {
    my $self = shift;
    my $nodes = $self->{_dbix}->parent->nodes;
    if ($nodes) {
    return $nodes->count;}
    else {
        return 0;
    }
}

sub getPublicIps {
    my $self = shift;

    my $publicip_rs = $self->{_dbix}->ipv4_publics;
    my $i =0;
    my @pub_ip =();
    while ( my $publicip_row = $publicip_rs->next ) {
        my $publicip = {publicip_id => $publicip_row->get_column('ipv4_public_id'),
                        address => $publicip_row->get_column('ipv4_public_address'),
                        netmask => $publicip_row->get_column('ipv4_public_mask'),
                        gateway => $publicip_row->get_column('ipv4_public_default_gw'),
                        name     => "eth0:$i",
                        cluster_id => $self->{_dbix}->get_column('cluster_id'),
        };
        $i++;
        push @pub_ip, $publicip;
    }
    return \@pub_ip;
}

=head2 getQoSConstraints

    Class : Public

    Desc :

=cut

sub getQoSConstraints {
    my $self = shift;
    my %args = @_;

    # TODO retrieve from db (it's currently done by RulesManager, move here)
    return { max_latency => 22, max_abort_rate => 0.3 } ;
}

=head2 addNode

=cut

sub addNode {
    my $self = shift;
    my %args = @_;
    my %params = (cluster_id  => $self->getAttr(name => "cluster_id"));

    my $adm = Administrator->new();

    # Check Rights
    # addNode method concerns an existing entity so we use his entity_id
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id},
                                                   method    => 'addNode');
    if (not $granted) {
        throw Kanopya::Exception::Permission::Denied(
                  error => "Permission denied to add a node to this cluster"
              );
    }

    $log->debug("New Operation AddNode with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'AddNode',
        params   => \%params
    );
}

sub getHostConstraints {
    my $self = shift;

    #TODO BIG IA, HYPER INTELLIGENCE TO REMEDIATE CONSTRAINTS CONFLICTS
    my $components = $self->getComponents(category=>"all");

    # Return the first constraint found.
    foreach my $k (keys %$components) {
        my $constraints = $components->{$k}->getHostConstraints();
        if ($constraints){
            return $constraints;
        }
    }
    return;
}

=head2 removeNode

=cut

sub removeNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['host_id']);

    my $adm = Administrator->new();
    # removeNode method concerns an existing entity so we use his entity_id
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'removeNode');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to remove a node from this cluster");
       }
    my %params = (
        cluster_id => $self->getAttr(name =>"cluster_id"),
        host_id => $args{host_id},
    );
    $log->debug("New Operation PreStopNode with attrs : " . %params);

    Operation->enqueue(
        priority => 200,
        type     => 'PreStopNode',
        params   => \%params,
    );
}

=head2 start

=cut

sub start {
    my $self = shift;

    my $adm = Administrator->new();
    # start method concerns an existing entity so we use his entity_id
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'start');
    if (not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to start this cluster");
    }

    $self->addNode();
    $self->setState(state => 'starting');
    $self->save();

#    $log->debug("New Operation StartCluster with cluster_id : " . $self->getAttr(name=>'cluster_id'));
#    Operation->enqueue(
#        priority => 200,
#        type     => 'StartCluster',
#        params   => { cluster_id => $self->getAttr(name =>"cluster_id") },
#    );
}

=head2 stop

=cut

sub stop {
    my $self = shift;

    my $adm = Administrator->new();
    # stop method concerns an existing entity so we use his entity_id
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'stop');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to stop this cluster");
       }

    $log->debug("New Operation StopCluster with cluster_id : " . $self->getAttr(name=>'cluster_id'));
    Operation->enqueue(
        priority => 200,
        type     => 'StopCluster',
        params   => { cluster_id => $self->getAttr(name =>"cluster_id") },
    );
}



=head2 getState

=cut

sub getState {
    my $self = shift;
    my $state = $self->{_dbix}->get_column('cluster_state');
    return wantarray ? split(/:/, $state) : $state;
}

=head2 setState

=cut

sub setState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['state']);
    my $new_state = $args{state};
    my $current_state = $self->getState();
    $self->{_dbix}->update({'cluster_prev_state' => $current_state,
                            'cluster_state' => $new_state.":".time})->discard_changes();;
}


sub getNewNodeNumber {
	my $self = shift;
	my $nodes = $self->getHosts();
	
	# if no nodes already registered, number is 1
	if(! keys %$nodes) { return 1; }
	
	my @current_nodes_number = ();
	while( my ($host_id, $host) = each(%$nodes) ) {
		push @current_nodes_number, $host->getNodeNumber();	
	}
	@current_nodes_number = sort(@current_nodes_number);
	$log->debug("Nodes number sorted: ".Dumper(@current_nodes_number));
	
	my $counter = 1;
	for my $number (@current_nodes_number) {
		if("$counter" eq "$number") {
			$counter += 1;
			next;
		} else {
			return $counter;
		}
	}
	return $counter;
}

sub addManagerParameter {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'manager_type', 'name', 'value' ]);

    Entity::ManagerParameter->new(
        cluster_id => $self->getAttr(name => 'cluster_id'),
        manager_id => $self->getAttr(name => $args{manager_type} . '_id'),
        name       => $args{name},
        value      => $args{value},
    );
}

sub getManagerParameters {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'manager_type' ]);

    my @parameters = Entity::ManagerParameter->search(
        hash => {
            cluster_id => $self->getAttr(name => 'cluster_id'),
            manager_id => $self->getAttr(name => $args{manager_type} . '_id'),
        }
    );

    my $params_hash = {};
    for my $param (@parameters) {
        $params_hash->{$param->getAttr(name => 'name')}
            = $param->getAttr(name => 'value');
    }
    return $params_hash;
}

=head2 _getNodesMetrics

    Desc: call collector manager to retrieve nodes metrics values.
    return \%data;

=cut

sub getNodesMetrics {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['nodelist', 'timespan']);

    my $collector_manager_id = $self->getAttr ( name=>'collector_manager_id' );
    my $collector_manager = Entity::Component->get ( id => $collector_manager_id ); 

    #return the data
    my $data = $collector_manager->retrieveData ( nodelist => $args{'nodelist'}, timespan => $args{'timespan'} );
    return $data;
}

1;
