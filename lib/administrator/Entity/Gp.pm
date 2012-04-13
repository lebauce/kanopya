# Entity::Gp.pm  

#    Copyright © 2011 Hedera Technology SAS
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
# Created 16 july 2010

=head1 NAME

Entity::Gp

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::Gp;
use base "Entity";

use strict;
use warnings;
use Kanopya::Exceptions;
use Administrator;
use General;
use Data::Dumper;
use Log::Log4perl "get_logger";


our $VERSION = "1.00";

my $log = get_logger("webui");
my $errmsg;

use constant ATTR_DEF => {
            gp_name            => {pattern            => '^\w*$',
                                        is_mandatory    => 1,
                                        is_extended        => 0,
                                        is_editable        => 1},
            gp_desc            => {pattern            => '^[\w\s]*$', 
                                        is_mandatory    => 0,
                                        is_extended     => 0,
                                        is_editable        => 1},
            gp_system        => {pattern            => '^\d$',
                                        is_mandatory    => 1,
                                        is_extended        => 0,
                                        is_editable        => 0},    
            gp_type            =>     {pattern            => '^\w*$',
                                        is_mandatory    => 1,
                                        is_extended        => 0,
                                        is_editable        => 0},
};

sub primarykey { return 'gp_id' }

sub methods {
    return {
        'create'    => {'description' => 'create a new group', 
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this group', 
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this group', 
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this group', 
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permission on this group', 
                        'perm_holder' => 'entity',
        },
        'appendEntity' => {'description' => 'add an element to group',
                            'perm_holder' => 'entity',
        },                    
        'removeEntity' => {'description' => 'remove an element from a group',
                            'perm_holder' => 'entity',
        }, 
    };
}

=head2 getGroups

    Class: public
    desc: retrieve several Entity::Gp instances
    args:
        hash : hashref : where criteria
    return: @ : array of Entity::Gp instances
    
=cut

sub getGroups {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

=head2 create

=cut

sub create {
    my $self = shift;
    my $admin = Administrator->new();
    my $mastergroup_eid = $self->getMasterGroupEid();
       my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $mastergroup_eid, method => 'create');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new group");
       }
     $self->save();      
}

=head2 update

=cut

sub update {}

=head2 remove

=cut

sub remove {}

=head2 getSize

    Class : public
    Desc  : return the number of entities in this group
    return : scalar (int)

=cut

sub getSize {
    my $self = shift;
    return $self->{_dbix}->ingroups->count();
}

=head2 getGroupsFromEntity

    Class: public
    desc: retrieve Entity::Gp instances that contains the Entity argument
    args:
        entity : Entity::* : an Entity instance
    return: @ : array of Entity::Gp instances
    
=cut

sub getGroupsFromEntity {
    my $class = shift;
    my %args = @_;
    my @groups = ();
    
    General::checkParams(args => \%args, required => ['entity']);
    
    if(not $args{entity}->{_dbix}->in_storage ) { return @groups; } 
        
    my $adm = Administrator->new();
       my $mastergroup = $args{entity}->getMasterGroupName();
    my $gp_rs = $adm->{db}->resultset('Gp')->search(
		{
        -or => [
            'ingroups.entity_id' => $args{entity}->{_dbix}->id,
            'gp_name' => $mastergroup ]
        },
        { join => [qw/ingroups/] }
    );
    while(my $row = $gp_rs->next) {
        eval {
            my $group = $class->get(id => $row->get_column('gp_id'));
            push(@groups, $group);    
        };
        if($@) {
            my $exception = $@;
            if(Kanopya::Exception::Permission::Denied->caught()) {
                next;
            }
            else { $exception->rethrow(); } 
        }
    }
       return @groups;
}

=head2 appendEntity

    Class : Public
    
    Desc : append an entity object to the groups ; the entity must have been saved to the database before adding it to a group.
        
    args:
        entity : Entity::* object : an Entity object

=cut

sub appendEntity {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['entity']);
    
#    my $entity_id = $args{entity}->{_dbix}->get_column('entity_id');
 	my $entity_id = $args{entity}->{_dbix}->id;
    $self->{_dbix}->ingroups->create({gp_id => $self->getAttr(name => 'gp_id'), entity_id => $entity_id} );
    return;
}

=head2 removeEntity

    Class : Public
    
    Desc : remove an entity object from the groups
    
    args:
        entity : Entity::* object : an Entity object contained by the groups

=cut

sub removeEntity {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['entity']);
    
    my $entity_id = $args{entity}->{_dbix}->id;
    $self->{_dbix}->ingroups->find({entity_id => $entity_id})->delete();
    return;
}

=head2 getEntities

    Desc : get all entities contained in the group
    
    return : @: array of entities 

=cut

sub getEntities {
    my $self = shift;
    my $adm = Administrator->new();    
    my $type = $self->{_dbix}->get_column('gp_type');
    my $entity_class = 'Entity::'.$type;
    require 'Entity/'.$type.'.pm';
        
    my $entities_rs = $self->{_dbix}->ingroups;
    my $ids = [];
    my $idfield = lc($type)."_id";
    
    while(my $row = $entities_rs->next) {
        my $concret = $adm->{db}->resultset($type)->find($row->get_column('entity_id'));
        push @$ids, $concret->id;
    }    
    
    my @objs = ();
    foreach my $id (@$ids) {
        my $e = eval { $entity_class->get(id => $id) };
        if($@) {
            my $exception = $@;
            if(Kanopya::Exception::Permission::Denied->caught()) {
                next;
            } 
            else { $exception->rethrow(); } 
        }
        push @objs, $e; 
    }    
        
    return @objs;
}

=head2 getExcludedEntities
    
    Desc : get all entities of the same type not contained in the group
    
    return : array of entities 

=cut

sub getExcludedEntities {
    my $self = shift;
    my $adm = Administrator->new();    
    my $type = $self->{_dbix}->get_column('gp_type');
    my $entity_class = 'Entity::'.$type;
    require 'Entity/'.$type.'.pm';
    
    my $entities_rs = $self->{_dbix}->ingroups;
    my $ids = [];
    my $idfield = lc($type)."_id";
    my $systemfield = lc($type)."_system";
    
    # retrieve groups elements ids 
    while(my $row = $entities_rs->next) {
        my $concret = $adm->{db}->resultset($type.'Entity')->search({entity_id => $row->id})->first;
        push @$ids, $concret->get_column("$idfield");
    }    
    
    # get (if granted) elements not already in the group 
    my @objs = ();
    my $where_clause = { "$idfield" => { -not_in => $ids }};
    # don't include system element
    if($adm->{db}->resultset($type)->result_source->has_column("$systemfield")) {
        $where_clause->{"$systemfield"} = 0;
    }
    
    #$log->debug(Dumper $where_clause);
    
    $entities_rs = $adm->{db}->resultset($type)->search($where_clause);
    while(my $row = $entities_rs->next) {
        my $entity = eval { $entity_class->get(id => $row->get_column("$idfield")); };
        if($@) {
            my $exception = $@;
            if(Kanopya::Exception::Permission::Denied->caught()) {
                next;
            } 
            else { $exception->rethrow(); }
        }
        else { push @objs, $entity; }    
    }
    
    return @objs;
}

sub getAttrDef{
    return ATTR_DEF;
}
=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('gp_name');
    return $string;
}

1;
