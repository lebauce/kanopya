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
package KanopyaUI::Permissions;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Entity::User;
use Entity::Gp;
use Log::Log4perl "get_logger";

my $log = get_logger("webui");

sub view_selectactors : StartRunmode {
    my $self = shift;
    my $query = $self->query();
    my $entitytype = $query->param('entitytype');
    my $tmpl = $self->load_tmpl('Permissions/view_selectactors.tmpl');
    $tmpl->param('titlepage' => "Permissions - who");
    $tmpl->param('mSettings' => 1);
    $tmpl->param('submPermissions' => 1);
    $tmpl->param('username' => $self->session->param('username'));
    
    # build entity type list
    if(not $entitytype) { $entitytype = 'Cluster'; }
    my $entitychoice = [];
    foreach my $e (qw/Motherboardmodel Processormodel Cluster Motherboard Systemimage Distribution Kernel User/) {
        my $tmp = {};
        $tmp->{entity} = $e;
        if($e eq $entitytype) {
            $tmp->{selected} = 'selected';
        }
        else {
            $tmp->{selected} = '';
        }
        push @$entitychoice, $tmp;
    }
    $tmpl->param('entitychoice' => $entitychoice);
    
    my $entitymodule = 'Entity/'.$entitytype.'.pm';
    my $entityclass = 'Entity::'.$entitytype;
    eval { require $entitymodule };
    if($@) {
        my $exception = $@;
        $exception->rethrow();
    }
    
    # get entity list
    my @entities = $entityclass->getEntities(hash => {}, type => $entitytype);
    my $entitylist = [];
    foreach my $e (@entities) {
        my $tmp = {};
        $tmp->{entity_id} = $e->{_entity_id};
        $tmp->{entity} = $e->toString();
        $tmp->{entitytype} = $entitytype;
        push @$entitylist, $tmp;
    }
    $tmpl->param('entitylist' => $entitylist);
    
    # get entity groups list
    my @egroups = Entity::Gp->getGroups(hash => {gp_type => $entitytype});
    my $groupslist = [];
    foreach my $e (@egroups) {
        my $tmp = {};
        $tmp->{entity_id} = $e->{_entity_id};
        $tmp->{groups} = $e->toString();
        $tmp->{entitytype} = 'Gp';
        push @$groupslist, $tmp;
    }
    $tmpl->param('groupslist' => $groupslist);
    
    
    # get users list
    my @eusers = Entity::User->getUsers(hash => {user_system => 0});
    my $users = [];
    foreach my $u (@eusers) {
        my $tmp = {};
        $tmp->{entity_id} = $u->{_entity_id};
        $tmp->{user} = $u->toString();
        $tmp->{entitytype} = 'User';
        push @$users, $tmp;
    }
    $tmpl->param('userslist' => $users);
    
    # get users'groups list
    my @eusersgroups = Entity::Gp->getGroups(hash => {gp_type => 'User'});
    my $usersgroups = [];
    foreach my $ug (@eusersgroups) {
        my $tmp = {};
        $tmp->{entity_id} = $ug->{_entity_id};
        $tmp->{groups} = $ug->toString();
        $tmp->{entitytype} = 'Gp';
        push @$usersgroups, $tmp;
    }
    $tmpl->param('usersgroupslist' => $usersgroups);
    
    $tmpl->param('entitytype' => $entitytype);
    
    return $tmpl->output();
    
}

sub view_selectconsumer : Runmode {
    my $self = shift;
    my $query = $self->query();
    my $entitytype = $query->param('entitytype');
    my $id = $query->param('id');
    
    my $tmpl = $self->load_tmpl('Permissions/view_selectconsumer.tmpl');
    $tmpl->param('titlepage' => "Permissions");
    $tmpl->param('mSettings' => 1);
    $tmpl->param('submPermissions' => 1);
    $tmpl->param('username' => $self->session->param('username'));
        
    my $entitymodule = 'Entity/'.$entitytype.'.pm';
    my $entityclass = 'Entity::'.$entitytype;
    eval { require $entitymodule };
    if($@) {
        my $exception = $@;
        $exception->rethrow();
    }
    $tmpl->param('entitytype' => $entitytype);
    my $entity = $entityclass->get(id => $id);
    $tmpl->param('entity_id' => $entity->{_entity_id});
    $tmpl->param('entity_name' => $entity->toString());
    
    # get users list
    my @eusers = Entity::User->getUsers(hash => {user_system => 0});
    my $users = [];
    foreach my $u (@eusers) {
        my $tmp = {};
        $tmp->{entity_id} = $u->{_entity_id};
        $tmp->{user} = $u->toString();
        $tmp->{entitytype} = 'User';
        push @$users, $tmp;
    }
    $tmpl->param('userslist' => $users);
    
    # get users'groups list
    my @eusersgroups = Entity::Gp->getGroups(hash => {gp_type => 'User'});
    my $usersgroups = [];
    foreach my $ug (@eusersgroups) {
        my $tmp = {};
        $tmp->{entity_id} = $ug->{_entity_id};
        $tmp->{groups} = $ug->toString();
        $tmp->{entitytype} = 'Groups';
        push @$usersgroups, $tmp;
    }
    $tmpl->param('usersgroupslist' => $usersgroups);
    
    return $tmpl->output();
}


sub form_permissionsettings : Runmode {
    my $self = shift;
    my $query = $self->query();
    my $consumertype = $query->param('consumertype');
    my $consumedtype = $query->param('consumedtype');
    
    my $entitymodule = 'Entity/'.$consumedtype.'.pm';
    my $entityclass = 'Entity::'.$consumedtype;
    eval { require $entitymodule };
    if($@) {
        my $exception = $@;
        return $exception;
    }
    
    # get all methods provided by this class and build a sorted list
    my $methods = $entityclass->methods();
    my @sortmethodslist = ();
    foreach my $m (keys %$methods) {
        push @sortmethodslist, $m;
    }
    @sortmethodslist = sort @sortmethodslist;
    
    
    # get all granted method for consumer/consumed arguments
    my @grantedmethods = $self->{adm}->{_rightchecker}->getGrantedMethods(
        consumer_id => $query->param('consumer_id'),
        consumed_id => $query->param('consumed_id'),
    );
                
    my $tmpl = $self->load_tmpl('Permissions/form_permissionsettings.tmpl');
        
    my $methodlist = [];
    foreach my $m (@sortmethodslist) {
        my $tmp = {};
        $tmp->{method} = $m;
        $tmp->{description} = $methods->{$m}->{'description'};
        $tmp->{checked} = '';
        foreach my $md (@grantedmethods) {
            if($md eq $m) { $tmp->{checked} = 'checked'; }
        }
        
        push @$methodlist, $tmp;
    }
    
    $tmpl->param('methods' => $methodlist);
    $tmpl->param('consumer_id' => $query->param('consumer_id'));
    $tmpl->param('consumed_id' => $query->param('consumed_id'));
    $tmpl->param('consumed_type' => $query->param('$consumedtype'));
    return $tmpl->output();
}

sub process_permissionsettings : Runmode {
    my $self = shift;
    my $query = $self->query();
    my @methods = $query->param('methods');
    $self->{'adm'}->{'_rightchecker'}->updatePerms(
        consumer_id => $query->param('consumer_id'),
        consumed_id => $query->param('consumed_id'),
        methods => \@methods
    );
    
    
    return $self->close_window();
}