package KanopyaUI::Groups;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Data::FormValidator::Constraints qw( email FV_eq_with );
use Data::Dumper;
use Log::Log4perl "get_logger";
use Entity::Groups;

my $log = get_logger('administrator');

# groups listing page

sub view_groups : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Groups/view_groups.tmpl');
    $tmpl->param('titlepage' => "Settings - Groups");
    $tmpl->param('mSettings' => 1);
	$tmpl->param('submGroups' => 1);
	$tmpl->param('username' => $self->session->param('username'));
	
	my @egroups = Entity::Groups->getGroups(hash => { groups_system => 0 });
	my $groups = [];
	
	foreach my $group (@egroups) {
		my $tmp = {};
		$tmp->{groups_id} = $group->getAttr('name' => 'groups_id');
		$tmp->{groups_name} = $group->getAttr('name' => 'groups_name'); 
		$tmp->{groups_desc} = $group->getAttr('name' => 'groups_desc');
		$tmp->{groups_type} = $group->getAttr('name' => 'groups_type');
		push(@$groups, $tmp);
	}
	$tmpl->param('groups_list' => $groups);
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
    my $egroup = Entity::Groups->new( 
    	groups_name => $query->param('groups_name'), 
    	groups_desc => $query->param('groups_desc'),
    	groups_type => $query->param('groups_type'),
    	groups_system => 0,
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
    	required => ['groups_name', 'groups_type'],
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
		my @egroup = $admin->getEntities(type => 'Groups', hash => { groups_name => $groupsname });
		return (scalar(@egroup) < 1);
	}
}

# group details page

sub view_groupdetails : Runmode {
	my $self = shift;
    	
	my $query = $self->query();
	my $groups_id = $query->param('groups_id');
	my $egroups = eval { Entity::Groups->get(id => $groups_id) };
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
		
		$tmpl->param('groups_id' =>  $groups_id);
		$tmpl->param('groups_name' =>  $egroups->getAttr('name' => 'groups_name'));
		$tmpl->param('groups_desc' =>  $egroups->getAttr('name' => 'groups_desc'));
		$tmpl->param('groups_type' =>  $egroups->getAttr('name' => 'groups_type'));
		
		my @entities = $egroups->getEntities();
		my $content = [];
		foreach my $e (@entities) {
			my $tmp = {};
			$tmp->{content_id} = $e->getAttr('name' => lc($tmpl->param('groups_type')).'_id');
			$tmp->{content_label} = $e->toString();
			$tmp->{groups_id} = $groups_id;
			push(@$content, $tmp) 
		}
		$tmpl->param('content_list' => $content);
		$tmpl->param('content_count' => scalar(@$content)+1);
		return $tmpl->output();
	}
}

# deletegroup processing 

sub process_deletegroup : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $groups_id = $query->param('groups_id');
	my $egroups = Entity::Groups->get(id => $groups_id);
	$egroups->delete();
	$self->redirect('/cgi/kanopya.cgi/groups/view_groups');
}

# appendentity form

sub form_appendentity : Runmode {
	my $self = shift;
	my $tmpl = $self->load_tmpl('Groups/form_appendentity.tmpl');
	my $query = $self->query();
	my $egroups = Entity::Groups->get(id => $query->param('groups_id'));
	$tmpl->param('groups_id' => $query->param('groups_id'));
	$tmpl->param('groups_name' => $egroups->getAttr('name' => 'groups_name'));
	my $type = $egroups->getAttr('name' => 'groups_type');
	$tmpl->param('groups_type' => $type);
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
	my $groups_id = $query->param('groups_id');
	my $real_id = $query->param('real_id');
	my $egroups = Entity::Groups->get(id => $groups_id);
	my $groups_type = $egroups->getAttr('name' => 'groups_type');
	my $module = "Entity/".$groups_type.".pm";
	my $class = "Entity::".$groups_type;
	eval { require $module; };
	my $entity = $class->get(id => $real_id);
	$egroups->appendEntity(entity => $entity);
	return $self->close_window();
}

# removeentity processing

sub process_removeentity : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $groups_id = $query->param('groups_id');
	my $real_id = $query->param('real_id');
	my $egroups = Entity::Groups->get(id => $groups_id);
	my $groups_type = $egroups->getAttr('name' => 'groups_type');
	
	my $module = "Entity/".$groups_type.".pm";
	my $class = "Entity::".$groups_type;
	eval { require $module; };
	my $entity = $class->get(id => $real_id);
	
	$egroups->removeEntity(entity => $entity);
	$self->redirect("/cgi/kanopya.cgi/groups/view_groupdetails?groups_id=$groups_id");
}

# edituser form

sub form_editgroup : Runmode {
	return "TODO";
}

1;