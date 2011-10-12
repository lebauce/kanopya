# Infrastructure.pm - This object allows to manipulate cluster configuration
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
package Entity::Infrastructure;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use General;

use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;
use constant ATTR_DEF => {
    infrastructure_reference=>  {pattern        => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    infrastructure_name =>      {pattern        => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 0},
    infrastructure_min_node =>  {pattern         => '^\d*$',
                                 is_mandatory    => 1,
                                 is_extended     => 0,
                                 is_editable        => 1},
    infrastructure_max_node  => {pattern            => '^\d*$',
                                 is_mandatory    => 1,
                                 is_extended        => 0,
                                 is_editable        => 1},
    infrastructure_tier_number  => {pattern            => '^\d*$',
                                 is_mandatory    => 1,
                                 is_extended        => 0,
                                 is_editable        => 1},
    infrastructure_priority  => {pattern            => '^\d*$',
                                 is_mandatory    => 1,
                                 is_extended        => 0,
                                 is_editable        => 1},
    infrastructure_desc            =>  {pattern        => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
    infrastructure_version            =>  {pattern        => '^.*$',
                                 is_mandatory    => 0,
                                 is_extended    => 0,
                                 is_editable    => 0},
    infrastructure_state            => {pattern         => '^up:\d*|down:\d*|starting:\d*|stopping:\d*$',
                                is_mandatory    => 0,
                                is_extended     => 0,
                                is_editable        => 0},
    infrastructure_domainname      => {pattern         => '^[a-z0-9-]+(\.[a-z0-9-]+)+$',
                                is_mandatory    => 1,
                                is_extended     => 0,
                                is_editable        => 0},
    infrastructure_nameserver        => {pattern         => '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$',
                                is_mandatory    => 1,
                                is_extended     => 0,
                                is_editable        => 0},
    };

sub methods {
    return {
        'create'    => {'description' => 'create a new infrastructure',
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this infrastructure',
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this infrastructure',
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this infrastructure',
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
        'addTier'    => {'description' => 'add a tier to this infrastructure',
                        'perm_holder' => 'entity',
        },
        'removeTier'    => {'description' => 'remove a tier from this infrastructure',
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
    my $dbix_infrastructure = $admin->{db}->resultset('Infrastructure')->find($args{id});
    if(not defined $dbix_infrastructure) {
        $errmsg = "Entity::Infrastructure->get : id <$args{id}> not found !";
     $log->error($errmsg);
     throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    my $entity_id = $dbix_infrastructure->entitylink->get_column('entity_id');
    my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get infrastructure with id $args{id}");
    }
    my $self = $class->SUPER::get( %args,  table => "Infrastructure");
    $self->{_ext_attrs} = $self->getExtendedAttrs(ext_table => "infrastructuredetails");
    return $self;
}

=head2 getInfrastructures

=cut

sub getInfrastructures {
    my $class = shift;
    my %args = @_;
    my @objs = ();
    my ($rs, $entity_class);

    General::checkParams(args => \%args, required => ['hash']);

    return $class->SUPER::getEntities( %args,  type => "Infrastructure");
}

sub getInfrastructure {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    my @infrastructures = $class->SUPER::getEntities( %args,  type => "Infrastructure");
    return pop @infrastructures;
}

=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Check attrs ad throw exception if attrs missed or incorrect
    my $attrs = $class->checkAttrs(attrs => \%args);

    # We create a new DBIx containing new entity (only global attrs)
    my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Infrastructure");

    # Set the extended parameters
    $self->{_ext_attrs} = $attrs->{extended};

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
    # Before infrastructure creation check some integrity configuration
    # Check if min node <
    $log->info("###### Infrastructure creation with min node <".$self->getAttr(name => "infrastructure_min_node") . "> and max node <". $self->getAttr(name=>"infrastructure_max_node").">");
    if ($self->getAttr(name => "infrastructure_min_node") > $self->getAttr(name=>"infrastructure_max_node")){
	throw Kanopya::Exception::Internal::WrongValue(error=> "Min node is superior to max node");
    }

    my %params = $self->getAttrs();
    $log->debug("New Operation Create with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'AddInfrastructure',
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
    $params{'infrastructure_id'}= $self->getAttr(name =>"infrastructure_id");
    $log->debug("New Operation Remove Infrastructure with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveInfrastructure',
        params   => \%params,
    );
}

sub forceStop {
    my $self = shift;
    my $adm = Administrator->new();
    # delete method concerns an existing entity so we use his entity_id
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'forceStop');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to force stop this entity");
       }
    my %params;
    $params{'infrastructure_id'}= $self->getAttr(name =>"infrastructure_id");
    $log->debug("New Operation Force Stop Infrastructure with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'ForceStopInfrastructure',
        params   => \%params,
    );
}

sub activate {
    my $self = shift;

    $log->debug("New Operation ActivateInfrastructure with infrastructure_id : " . $self->getAttr(name=>'infrastructure_id'));
    Operation->enqueue(priority => 200,
                   type     => 'ActivateInfrastructure',
                   params   => {infrastructure_id => $self->getAttr(name=>'infrastructure_id')});
}

sub deactivate {
    my $self = shift;

    $log->debug("New Operation DeactivateInfrastructure with infrastructure_id : " . $self->getAttr(name=>'infrastructure_id'));
    Operation->enqueue(priority => 200,
                   type     => 'DeactivateInfrastructure',
                   params   => {infrastructure_id => $self->getAttr(name=>'infrastructure_id')});
}

sub getAttrDef{
    return ATTR_DEF;
}


=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('infrastructure_name');
    return $string;
}

=head2 getTiers

    Desc : This function get components used in a infrastructure. This function allows to select
            category of tiers or all of them.
    args:
        administrator : Administrator : Administrator object to instanciate all tiers
        category : String : Tier category
    return : a hashref of tiers, it is indexed on tier_instance_id

=cut

sub getTiers {
    my $self = shift;
    my %args = @_;
    my %tiers;

    General::checkParams(args => \%args, required => []);
#TODO Infrastructure->getTiers

    return \%tiers;
}

=head2 getTier

    Desc : This function get tier used in a infrastructure. This function allows to select
            a particular tier with its name and version.
    args:
        administrator : Administrator : Administrator object to instanciate all tiers
        name : String : Tier name
        version : String : Tier version
    return : a tier instance

=cut

sub getTier{
    my $self = shift;
    my %args = @_;
    my $tier;

    General::checkParams(args => \%args, required => ['name','version']);

    return $tier;
}

=head2 addTier

create a new tier instance
this is the first step of infrastructure setting

=cut

sub addTier {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['tier_id']);

    my $tierinstance = Entity::Tier->new(%args, infrastructure_id => $self->getAttr(name => "infrastructure_id"));
    my $tier_instance_id = $tierinstance->save();

    my $internal_infrastructure = Entity::Infrastructure->getInfrastructure(hash => {infrastructure_name => 'adm'});
    $log->info('linternal infrastructure;'.Dumper($internal_infrastructure));
    # Insert default configuration in db
    # Remark: we must get concrete instance here because the tier->new (above) return an Entity::Tier and not a concrete child tier
    #          There must be a way to do this more properly (tier management).
    my $concrete_tier = Entity::Tier->getInstance(id => $tier_instance_id);
    $concrete_tier->insertDefaultConfiguration(internal_infrastructure => $internal_infrastructure);
    return $tier_instance_id;
}

=head2 removeTier

remove a tier instance and all its configuration
from this infrastructure

=cut

sub removeTier {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['tier_instance_id']);

    my $tier_instance = Entity::Tier->get(id => $args{tier_instance_id});
    $tier_instance->delete;

}

=head2 getMotherboards

    Desc : This function get motherboards executing the infrastructure.
    args:
        administrator : Administrator : Administrator object to instanciate all tiers
    return : a hashref of motherboard, it is indexed on motherboard_id

=cut

sub getMotherboards {
    my $self = shift;

    my $motherboard_rs = $self->{_dbix}->nodes;
    my %motherboards;
    while ( my $node_row = $motherboard_rs->next ) {
        my $motherboard_row = $node_row->motherboard;
        $log->debug("Nodes found");
        my $motherboard_id = $motherboard_row->get_column('motherboard_id');
        eval { $motherboards{$motherboard_id} = Entity::Motherboard->get (
                        id => $motherboard_id,
                        type => "Motherboard") };
    }
    return \%motherboards;
}

=head2 getCurrentNodesCount

    class : public
    desc : return the current nodes count of the infrastructure

=cut

sub getCurrentNodesCount {
    my $self = shift;
    my $nodes = $self->{_dbix}->nodes;
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
                        infrastructure_id => $self->{_dbix}->get_column('infrastructure_id'),
        };
        $i++;
        push @pub_ip, $publicip;
    }
    return \@pub_ip;
}


=head2 start

=cut

sub start {
    my $self = shift;

    my $adm = Administrator->new();
    # start method concerns an existing entity so we use his entity_id
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'start');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to start this infrastructure");
       }

    $log->debug("New Operation StartInfrastructure with infrastructure_id : " . $self->getAttr(name=>'infrastructure_id'));
    Operation->enqueue(
        priority => 200,
        type     => 'StartInfrastructure',
        params   => { infrastructure_id => $self->getAttr(name =>"infrastructure_id") },
    );
}

=head2 stop

=cut

sub stop {
    my $self = shift;

    my $adm = Administrator->new();
    # stop method concerns an existing entity so we use his entity_id
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'stop');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to stop this infrastructure");
       }

    $log->debug("New Operation StopInfrastructure with infrastructure_id : " . $self->getAttr(name=>'infrastructure_id'));
    Operation->enqueue(
        priority => 200,
        type     => 'StopInfrastructure',
        params   => { infrastructure_id => $self->getAttr(name =>"infrastructure_id") },
    );
}



=head2 getState

=cut

sub getState {
    my $self = shift;
    my $state = $self->{_dbix}->get_column('infrastructure_state');
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
    $self->{_dbix}->update({'infrastructure_prev_state' => $current_state,
                            'infrastructure_state' => $new_state.":".time})->discard_changes();;
}


1;
