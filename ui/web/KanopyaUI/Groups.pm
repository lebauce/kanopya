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
package KanopyaUI::Groups;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Data::FormValidator::Constraints qw( email FV_eq_with );
use Data::Dumper;
use Log::Log4perl "get_logger";
use Entity::Gp;

my $log = get_logger('webui');

# groups listing page

sub view_groups : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Groups/view_groups.tmpl');
    $tmpl->param('titlepage' => "Settings - Groups");
    $tmpl->param('mSettings' => 1);
	$tmpl->param('submGroups' => 1);
	$tmpl->param('username' => $self->session->param('username'));
	
	my @egroups = Entity::Gp->getGroups(hash => { gp_system => 0 });
	my $groups = [];
	
	foreach my $group (@egroups) {
		my $tmp = {};
		$tmp->{gp_id} = $group->getAttr('name' => 'gp_id');
		$tmp->{gp_name} = $group->getAttr('name' => 'gp_name'); 
		$tmp->{gp_desc} = $group->getAttr('name' => 'gp_desc');
		$tmp->{gp_type} = $group->getAttr('name' => 'gp_type');
		$tmp->{gp_size} = $group->getSize();
		push(@$groups, $tmp);
	}
	$tmpl->param('gp_list' => $groups);
	my $methods = Entity::Gp->getPerms();
	if($methods->{'create'}->{'granted'}) { $tmpl->param('can_create' => 1); }
	return $tmpl->output();
}

# addgroup form

sub form_addgroup : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Groups/form_addgroup.tmpl');
    $tmpl->param($errors) if $errors;
    return $tmpl->output();
}

# addgroup form processing

sub process_addgroup : Runmode {
	my $self = shift;
	use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addgroup', '_addgroup_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    my $egroup = Entity::Gp->new( 
    	gp_name => $query->param('gp_name'), 
    	gp_desc => $query->param('gp_desc'),
    	gp_type => $query->param('gp_type'),
    	gp_system => 0,
    );
    eval { $egroup->create(); };
	if($@) {
    	my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	}
	else { return $self->close_window(); }
}

# function profile for form_addgroup (see ValidateRM module)

sub _addgroup_profile {
	return {
    	required => ['gp_name', 'gp_type'],
        msgs => {
        	any_errors => 'some_errors',
        	prefix => 'err_',
        	constraints => {
        		'groupname_used' => 'name already used',
        	}
        },
        constraint_methods => {
        	groupsname => groupsname_used(),
        }
	};    
}

# function constraint for groupname field used in _addgroup_profile

sub groupsname_used {
	return sub {
		my $dfv = shift;
		$dfv->name_this('groupname_used');
		my $groupsname = $dfv->get_current_constraint_value();
		my $admin = Administrator->new(login => 'admin', password => 'admin');
		my @egroup = $admin->getEntities(type => 'Gp', hash => { gp_name => $groupsname });
		return (scalar(@egroup) < 1);
	}
}

# group details page

sub view_groupdetails : Runmode {
	my $self = shift;
    	
	my $query = $self->query();
	my $gp_id = $query->param('gp_id');
	my $egroups = eval { Entity::Gp->get(id => $gp_id) };
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{admin}->addMessage(from => 'Administrator', level => 'warning', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else {
			$exception->rethrow();
		}
	}
	else {
		my $tmpl =  $self->load_tmpl('Groups/view_groupdetails.tmpl');
	    $tmpl->param('titlepage' => "Groups - Group details");
	    $tmpl->param('mSettings' => 1);
		$tmpl->param('submGroups' => 1);
		$tmpl->param('username' => $self->session->param('username'));
		
		$tmpl->param('gp_id' =>  $gp_id);
		$tmpl->param('gp_name' =>  $egroups->getAttr('name' => 'gp_name'));
		$tmpl->param('gp_desc' =>  $egroups->getAttr('name' => 'gp_desc'));
		$tmpl->param('gp_type' =>  $egroups->getAttr('name' => 'gp_type'));
		
		my $methods = $egroups->getPerms();
		my @entities = $egroups->getEntities();
		my $content = [];
		foreach my $e (@entities) {
			my $tmp = {};
			$tmp->{content_id} = $e->getAttr('name' => lc($tmpl->param('gp_type')).'_id');
			$tmp->{content_label} = $e->toString();
			$tmp->{gp_id} = $gp_id;
			$tmp->{can_removeEntity} = $methods->{'removeEntity'}->{'granted'}; 
						
			push(@$content, $tmp) 
		}
		$tmpl->param('content_list' => $content);
		$tmpl->param('content_count' => scalar(@$content)+1);
				
		if($methods->{'update'}->{'granted'}) { $tmpl->param('can_update' => 1); }
		if($methods->{'remove'}->{'granted'}) { $tmpl->param('can_delete' => 1); }
		if($methods->{'appendEntity'}->{'granted'}) { $tmpl->param('can_appendEntity' => 1); }
		return $tmpl->output();
	}
}

# deletegroup processing 

sub process_deletegroup : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $gp_id = $query->param('gp_id');
	my $egroups = Entity::Gp->get(id => $gp_id);
	$egroups->delete();
	$self->redirect('/cgi/kanopya.cgi/groups/view_groups');
}

# appendentity form

sub form_appendentity : Runmode {
	my $self = shift;
	my $tmpl = $self->load_tmpl('Groups/form_appendentity.tmpl');
	my $query = $self->query();
	my $egroups = Entity::Gp->get(id => $query->param('gp_id'));
	$tmpl->param('gp_id' => $query->param('gp_id'));
	$tmpl->param('gp_name' => $egroups->getAttr('name' => 'gp_name'));
	my $type = $egroups->getAttr('name' => 'gp_type');
	$tmpl->param('gp_type' => $type);
	my $entity_list = [];
	my @entities = $egroups->getExcludedEntities();
	
	foreach my $e (@entities) {
		my $tmp = {};
		$tmp->{real_id} = $e->getAttr(name => lc($type)."_id");
		$tmp->{entity_label} = $e->toString();
		push(@$entity_list, $tmp);
	}
	$tmpl->param('entity_list' => $entity_list);
	return $tmpl->output();
}

# appendentity processing 

sub process_appendentity : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $gp_id = $query->param('gp_id');
	my $real_id = $query->param('real_id');
	my $egroups = Entity::Gp->get(id => $gp_id);
	my $gp_type = $egroups->getAttr('name' => 'gp_type');
	my $module = "Entity/".$gp_type.".pm";
	my $class = "Entity::".$gp_type;
	eval { require $module; };
	my $entity = $class->get(id => $real_id);
	$egroups->appendEntity(entity => $entity);
	return $self->close_window();
}

# removeentity processing

sub process_removeentity : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $gp_id = $query->param('gp_id');
	my $real_id = $query->param('real_id');
	my $egroups = Entity::Gp->get(id => $gp_id);
	my $gp_type = $egroups->getAttr('name' => 'gp_type');
	
	my $module = "Entity/".$gp_type.".pm";
	my $class = "Entity::".$gp_type;
	eval { require $module; };
	my $entity = $class->get(id => $real_id);
	
	$egroups->removeEntity(entity => $entity);
	$self->redirect("/cgi/kanopya.cgi/groups/view_groupdetails?gp_id=$gp_id");
}

# edituser form

sub form_editgroup : Runmode {
	return "TODO";
}

1;