# Tier.pm - This object allows to manipulate tier configuration
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
# Created 1 oct 2011
package Entity::Tier;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Component;
use Entity::Motherboard;
use Entity::Systemimage;
use Operation;
use Administrator;
use General;

use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;
use constant ATTR_DEF => {
    tier_name               =>  {pattern        => '^\w*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    tier_rank               =>  {pattern        => '^\d*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    tier_data_src           =>  {pattern        => '^.*$',
                                 is_mandatory    => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    tier_poststart_script   =>  {pattern        => '^.*$',
                                 is_mandatory    => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    active                  => {pattern            => '^[01]$',
                                is_mandatory    => 0,
                                is_extended        => 0,
                                is_editable        => 0},
    tier_state            => {pattern         => '^up:\d*|down:\d*|starting:\d*|stopping:\d*$',
                                is_mandatory    => 0,
                                is_extended     => 0,
                                is_editable        => 0},
    infrastructure_id     => {pattern        => '^\d*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0}
    };

sub methods {
    return {
        'create'    => {'description' => 'create a new tier',
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this tier',
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this tier',
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this tier',
                        'perm_holder' => 'entity',
        },
        'activate'=> {'description' => 'activate this tier',
                        'perm_holder' => 'entity',
        },
        'deactivate'=> {'description' => 'deactivate this tier',
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this tier',
                        'perm_holder' => 'entity',
        },
        'addComponent'    => {'description' => 'add a component to this tier',
                        'perm_holder' => 'entity',
        },
        'removeComponent'    => {'description' => 'remove a component from this tier',
                        'perm_holder' => 'entity',
        },
        'configureComponents'    => {'description' => 'configure components of this tier',
                        'perm_holder' => 'entity',
        },
    };
}

=head2 get

=cut

sub get {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);

    my $admin = Administrator->new();
    my $dbix_tier = $admin->{db}->resultset('Tier')->find($args{id});
    if(not defined $dbix_tier) {
        $errmsg = "Entity::Tier->get : id <$args{id}> not found !";
     $log->error($errmsg);
     throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    my $entity_id = $dbix_tier->entitylink->get_column('entity_id');
    my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get tier with id $args{id}");
    }
    my $self = $class->SUPER::get( %args,  table => "Tier");
    return $self;
}

=head2 getTiers

=cut

sub getTiers {
    my $class = shift;
    my %args = @_;
    my @objs = ();
    my ($rs, $entity_class);

    General::checkParams(args => \%args, required => ['hash']);

    return $class->SUPER::getEntities( %args,  type => "Tier");
}

sub getTier {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    my @tiers = $class->SUPER::getEntities( %args,  type => "Tier");
    return pop @tiers;
}

=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Check attrs ad throw exception if attrs missed or incorrect
    my $attrs = $class->checkAttrs(attrs => \%args);

    # We create a new DBIx containing new entity (only global attrs)
    my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Tier");

    return $self;
}

=head2 create

=cut

sub create {
    my $self = shift;

    my $admin = Administrator->new();
    my $mastergroup_eid = $self->getMasterGroupEid();
       my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $mastergroup_eid, method => 'create');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new user");
       }
    # Before tier creation check some integrity configuration
    # Check if min node <
    $log->info("###### Tier creation with min node <".$self->getAttr(name => "tier_min_node") . "> and max node <". $self->getAttr(name=>"tier_max_node").">");
    if ($self->getAttr(name => "tier_min_node") > $self->getAttr(name=>"tier_max_node")){
	throw Kanopya::Exception::Internal::WrongValue(error=> "Min node is superior to max node");
    }

    my %params = $self->getAttrs();
    $log->debug("New Operation Create with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'AddTier',
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
    $params{'tier_id'}= $self->getAttr(name =>"tier_id");
    $log->debug("New Operation Remove Tier with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveTier',
        params   => \%params,
    );
}

sub activate {
    my $self = shift;

    $log->debug("New Operation ActivateTier with tier_id : " . $self->getAttr(name=>'tier_id'));
    Operation->enqueue(priority => 200,
                   type     => 'ActivateTier',
                   params   => {tier_id => $self->getAttr(name=>'tier_id')});
}

sub deactivate {
    my $self = shift;

    $log->debug("New Operation DeactivateTier with tier_id : " . $self->getAttr(name=>'tier_id'));
    Operation->enqueue(priority => 200,
                   type     => 'DeactivateTier',
                   params   => {tier_id => $self->getAttr(name=>'tier_id')});
}

sub getAttrDef{
    return ATTR_DEF;
}


=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('tier_name');
    return $string;
}

=head2 getComponents

    Desc : This function get components used in a tier. This function allows to select
            category of components or all of them.
    args:
        category : String : Component category
    return : a hashref of components, it is indexed on component_instance_id

=cut

sub getComponents {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['category']);

#    my $adm = Administrator->new();
    my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", undef,
                                            { '+columns' => [ "component.component_name",
                                                              "component.component_category",
                                                              "component.component_version"],
                                                    join => ["component"]});

    my %comps;
    $log->debug("Category is $args{category}");
    while ( my $comp_instance_row = $comp_instance_rs->next ) {
        my $comp_category = $comp_instance_row->get_column('component_category');
        $log->debug("Component category: $comp_category");
        my $comp_instance_id = $comp_instance_row->get_column('component_instance_id');
        $log->debug("Component instance id: $comp_instance_id");
        my $comp_name = $comp_instance_row->get_column('component_name');
        $log->debug("Component name: $comp_name");
        my $comp_version = $comp_instance_row->get_column('component_version');
        $log->debug("Component version: $comp_version");
        if (($args{category} eq "all")||
            ($args{category} eq $comp_category)){
            $log->debug("One component instance found with " . ref($comp_instance_row));
#            my $class= "Entity::Component::" . $comp_category . "::" . $comp_name . $comp_version;
            my $class= "Entity::Component::" . $comp_name . $comp_version;
            my $loc = General::getLocFromClass(entityclass=>$class);
            eval { require $loc; };
            $comps{$comp_instance_id} = $class->get(id =>$comp_instance_id);
        }
    }
    return \%comps;
}

=head2 getComponent

    Desc : This function get component used in a tier. This function allows to select
            a particular component with its name and version.
    args:
        name : String : Component name
        version : String : Component version
    return : a component instance

=cut

sub getComponent{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['name','version']);

    my $hash = {'component.component_name' => $args{name}, 'component.component_version' => $args{version}};
    my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", $hash,
                                            { '+columns' => [ "component.component_name",
                                                              "component.component_version",
                                                              "component.component_category"],
                                                    join => ["component"]});

    $log->debug("name is $args{name}, version is $args{version}");
    my $comp_instance_row = $comp_instance_rs->next;
    if (not defined $comp_instance_row) {
        throw Kanopya::Exception::Internal(error => "Component with name '$args{name}' version $args{version} not installed on this tier");
    }
    $log->debug("Comp name is " . $comp_instance_row->get_column('component_name'));
    $log->debug("Component instance found with " . ref($comp_instance_row));
    my $comp_category = $comp_instance_row->get_column('component_category');
    my $comp_instance_id = $comp_instance_row->get_column('component_instance_id');
    my $comp_name = $comp_instance_row->get_column('component_name');
    my $comp_version = $comp_instance_row->get_column('component_version');
#    my $class= "Entity::Component::" . $comp_category . "::" . $comp_name . $comp_version;
    my $class= "Entity::Component::" . $comp_name . $comp_version;
    my $loc = General::getLocFromClass(entityclass=>$class);
    eval { require $loc; };
    return "$class"->get(id =>$comp_instance_id);
}

sub getComponentByInstanceId{
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['component_instance_id']);

    my $hash = {'component_instance_id' => $args{component_instance_id}};
    my $comp_instance_rs = $self->{_dbix}->search_related("component_instances", $hash,
                                            { '+columns' => [ "component.component_name",
                                                              "component.component_version",
                                                              "component.component_category"],
                                                    join => ["component"]});

    my $comp_instance_row = $comp_instance_rs->next;
    if (not defined $comp_instance_row) {
        throw Kanopya::Exception::Internal(error => "Component with component_instance_id '$args{component_instance_id}' not found on this tier");
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

=head2 addComponent

create a new component instance
this is the first step of tier setting

=cut

sub addComponent {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['component_id']);

    my $componentinstance = Entity::Component->new(%args, tier_id => $self->getAttr(name => "tier_id"));
    my $component_instance_id = $componentinstance->save();

    return $component_instance_id;
}

=head2 removeComponent

remove a component instance and all its configuration
from this tier

=cut

sub removeComponent {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['component_instance_id']);

    my $component_instance = Entity::Component->get(id => $args{component_instance_id});
    $component_instance->delete;

}

sub getDmzIps {
    my $self = shift;

    my $dmz_ip_rs = $self->{_dbix}->ipv4_dmzs;
    my $i =0;
    my @dmz_ip =();
    while ( my $dmz_ip_row = $dmz_ip_rs->next ) {
        my $dmzip = {   dmzip_id => $dmz_ip_row->get_column('ipv4_dmz_id'),
                        address => $dmz_ip_row->get_column('ipv4_dmz_address'),
                        netmask => $dmz_ip_row->get_column('ipv4_dmz_mask'),
                        tier_id => $self->{_dbix}->get_column('tier_id'),
        };
        $i++;
        push @dmz_ip, $dmzip;
    }
    return \@dmz_ip;
}

1;
