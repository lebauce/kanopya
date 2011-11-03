# User.pm - This object allows to manipulate User
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
# Created 11 sept 2010

package Entity::User;
use base "Entity";

use strict;
use warnings;
use Digest::MD5 "md5_hex";
use Kanopya::Exceptions;
use General;
use Log::Log4perl "get_logger";

our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
            user_login            => {pattern            => '^\w*$',
                                        is_mandatory    => 1,
                                        is_extended        => 0,
                                        is_editable        => 0},
            user_desc            => {pattern            => '^.*$', # Impossible to check char used because of \n doesn't match with \w
                                        is_mandatory    => 0,
                                        is_extended     => 0,
                                        is_editable        => 1},
            user_password        => {pattern            => '^.*$',
                                        is_mandatory    => 1,
                                        is_extended        => 0,
                                        is_editable        => 1},
            user_firstname        => {pattern            => '^\w*$',
                                        is_mandatory    => 1,
                                        is_extended        => 0,
                                        is_editable        => 0},
            user_lastname        => {pattern            => '^\w*$',
                                        is_mandatory    => 1,
                                        is_extended        => 0,
                                        is_editable        => 0},
            user_email            => {pattern            => '\w*$',
                                        is_mandatory    => 1,
                                        is_extended        => 0,
                                        is_editable        => 1},    
            user_creationdate    => {pattern            => '^*$',
                                        is_mandatory    => 0,
                                        is_extended        => 0,
                                        is_editable        => 0},
            user_lastaccess        => {pattern            => '^\w*$',
                                        is_mandatory    => 0,
                                        is_extended        => 0,
                                        is_editable        => 1},    
};

sub methods {
    return {
        'create'    => {'description' => 'create a new user', 
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this user', 
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this user', 
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this user', 
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this user', 
                        'perm_holder' => 'entity',
        },
    };
}

=head2 get

    Class: public
    desc: retrieve a stored Entity::User instance
    args:
        id : scalar(int) : user id
    return: Entity::User instance 

=cut

sub get {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);
      
    my $admin = Administrator->new();
    my $dbix_user = $admin->{db}->resultset('User')->find($args{id});
    if(not defined $dbix_user) {
        $errmsg = "Entity::User->get : id <$args{id}> not found !";    
     $log->error($errmsg);
     throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }       
    
    my $entity_id = $dbix_user->entitylink->get_column('entity_id');
    $log->debug("checking get permission on entity_id : $entity_id");
    my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
    if(not $granted) {
        $errmsg = "Permission denied to get user with id $args{id}";
        $log->error($errmsg);
        throw Kanopya::Exception::Permission::Denied(error => $errmsg);
    }
   
    my $self = $class->SUPER::get( %args,  table => "User");
    return $self;
}

=head2 getUsers

    Class: public
    desc: retrieve several Entity::User instances
    args:
        hash : hashref : where criteria
    return: @ : array of Entity::User instances
    
=cut

sub getUsers {
    my $class = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['hash']);
    
    if ((! exists $args{hash} or ! defined $args{hash})) { 
        $errmsg = "Entity::User->getUsers need a hash named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $adm = Administrator->new();
    return $class->SUPER::getEntities( %args,  type => "User");
}

=head2 new

    Public class method
    desc:  Constructor
    args: 
    return: Entity::User instance 
    
=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Check attrs ad throw exception if attrs missed or incorrect
    my $attrs = $class->checkAttrs(attrs => \%args);
        
    # We create a new DBIx containing new entity (only global attrs)
    my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "User");
    
    # Set the extended parameters
    #$self->{_ext_attrs} = $attrs->{extended};

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

    $self->{_dbix}->user_password( md5_hex($self->{_dbix}->user_password) );
    $self->{_dbix}->user_creationdate(\'NOW()');
    $self->{_dbix}->user_lastaccess(undef);
    $self->save();
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
    my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'remove');
    if(not $granted) {
        throw Kanopya::Exception::Permission::Denied(
            error => "Permission denied to delete user with id ".$self->getAttr(name =>'user_id')
        );
    }
    $self->SUPER::delete();
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('user_firstname'). " ". $self->{_dbix}->get_column('user_lastname');
    return $string;
}

sub getAttrDef{
    return ATTR_DEF;
}

1;
