package Mcsui::Users;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use Data::FormValidator::Constraints qw( email FV_eq_with );
use Data::Dumper;
use strict;
use warnings;

use Log::Log4perl "get_logger";
my $log = get_logger('administrator');

my $closewindow = "<script type=\"text/javascript\">window.opener.location.reload();window.close();</script>";

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'admin', password => 'admin');
}

# users and groups listing page

sub view_usersgroups : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Users/view_users.tmpl');
    $tmpl->param('titlepage' => "Settings - Users / Groups");
    $tmpl->param('mSettings' => 1);
	$tmpl->param('submUsers' => 1);
	
	my @eusers = $self->{'admin'}->getEntities(type => 'User', hash => { user_system => 0 });
	my $users = [];
	
	foreach my $user (@eusers) {
		my $tmp = {};
		$tmp->{user_id} = $user->getAttr('name' => 'user_id');
		$tmp->{user_firstname} = $user->getAttr('name' => 'user_firstname'); 
		$tmp->{user_lastname} = $user->getAttr('name' => 'user_lastname');
		
		push(@$users, $tmp);
	}
	$tmpl->param('users_list' => $users);
	
	my @egroups = $self->{'admin'}->getEntities(type => 'Groups', hash => { groups_system => 0 });
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

# adduser form

sub form_adduser : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Users/form_adduser.tmpl');
    $tmpl->param($errors) if $errors;
    return $tmpl->output();
}

# adduser form processing

sub process_adduser : Runmode {
	my $self = shift;
	use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_adduser', '_adduser_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    my $euser = $self->{admin}->newEntity(type => 'User', params => { 
    	user_login => $query->param('login'), 
    	user_password => $query->param('password'),
    	user_firstname => $query->param('firstname'),
    	user_lastname => $query->param('lastname'),
    	user_email => $query->param('email'),
    	user_desc => $query->param('desc'),
    	user_creationdate => \"NOW()",
    	user_lastaccess => undef
    });
    
    $euser->save();
    
    # TODO add this user in the User master group
    
    return $closewindow;
}

# function profile for form_adduser (see ValidateRM module)

sub _adduser_profile {
	return {
    	required => ['firstname', 'lastname', 'email', 'login', 'password', 'confirmpassword'],
        msgs => {
        	any_errors => 'some_errors',
        	prefix => 'err_',
        	constraints => {
        		'login_used' => 'login already used',
        	}
        },
        constraint_methods => {
        	login => login_used(),
        	email => email(),
        	confirmpassword => FV_eq_with('password'),
        }
	};    
}

# function constraint for login field used in _adduser_profile

sub login_used {
	return sub {
		my $dfv = shift;
		$dfv->name_this('login_used');
		my $login = $dfv->get_current_constraint_value();
		my $admin = Administrator->new(login => 'admin', password => 'admin');
		my @euser = $admin->getEntities(type => 'User', hash => { user_login => $login });
		return (scalar(@euser) < 1);
	}
}

# user details page

sub view_userdetails : Runmode {
	my $self = shift;
    my $tmpl =  $self->load_tmpl('Users/view_userdetails.tmpl');
    $tmpl->param('titlepage' => "Users - User details");
    $tmpl->param('mSettings' => 1);
	$tmpl->param('submUsers' => 1);
	
	my $query = $self->query();
	my $user_id = $query->param('user_id');
	my $euser = $self->{'admin'}->getEntity(type => 'User', id => $user_id);
	
	$tmpl->param('user_id' =>  $user_id);
	$tmpl->param('user_desc' =>  $euser->getAttr('name' => 'user_desc'));
	$tmpl->param('user_firstname' =>  $euser->getAttr('name' => 'user_firstname'));
	$tmpl->param('user_lastname' =>  $euser->getAttr('name' => 'user_lastname'));
	$tmpl->param('user_email' =>  $euser->getAttr('name' => 'user_email'));
	$tmpl->param('user_login' =>  $euser->getAttr('name' => 'user_login'));
	$tmpl->param('user_creationdate' =>  $euser->getAttr('name' => 'user_creationdate'));
	$tmpl->param('user_lastaccess' =>  $euser->getAttr('name' => 'user_lastaccess'));
	# password is not retrieved because displayed like ********
	
	my $groups = [];
	while( my $row = $euser->{_groups}->next) {
		my $tmp = {};
		$tmp->{groups_id} = $row->get_column('groups_id');
		$tmp->{groups_name} = $row->get_column('groups_name');
		$tmp->{groups_desc} = $row->get_column('groups_desc');
		$tmp->{groups_system} = $row->get_column('groups_system');
		push(@$groups, $tmp);
	} 
	
	$tmpl->param('groups_list' => $groups);
	
	return $tmpl->output();
}

# deleteuser processing

sub process_deleteuser : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $user_id = $query->param('user_id');
	# TODO verifier qu'il ne s'agit pas du user qui est loggé
	my $euser = $self->{admin}->getEntity(type => 'User', id => $user_id);
	$euser->delete();
	# TODO retirer le user des groups auquels il appartient
	# TODO supprimer tous les droits du user 
	$self->redirect('/cgi/mcsui.cgi/users/view_usersgroups');
}

# addgroup form

sub form_addgroup : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Users/form_addgroup.tmpl');
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
    my $egroup = $self->{admin}->newEntity(type => 'Groups', params => { 
    	groups_name => $query->param('groups_name'), 
    	groups_desc => $query->param('groups_desc'),
    	groups_type => $query->param('groups_type'),
    	groups_system => 0,
    });
    
    $egroup->save();
    
    # TODO add this user in the User master group
    
    return $closewindow;
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
    my $tmpl =  $self->load_tmpl('Users/view_groupdetails.tmpl');
    $tmpl->param('titlepage' => "Users - Group details");
    $tmpl->param('mSettings' => 1);
	$tmpl->param('submUsers' => 1);
	
	my $query = $self->query();
	my $groups_id = $query->param('groups_id');
	my $egroups = $self->{'admin'}->getEntity(type => 'Groups', id => $groups_id);
	
	$tmpl->param('groups_id' =>  $groups_id);
	$tmpl->param('groups_name' =>  $egroups->getAttr('name' => 'groups_name'));
	$tmpl->param('groups_desc' =>  $egroups->getAttr('name' => 'groups_desc'));
	$tmpl->param('groups_type' =>  $egroups->getAttr('name' => 'groups_type'));
	
	my @entities = $egroups->getEntities(administrator => $self->{admin});
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

# deletegroup processing 

sub process_deletegroup : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $groups_id = $query->param('groups_id');
	my $egroups = $self->{admin}->getEntity(type => 'Groups', id => $groups_id);
	$egroups->delete();
	# TODO retirer le user des groups auquels il appartient
	# TODO supprimer tous les droits du user 
	$self->redirect('/cgi/mcsui.cgi/users/view_usersgroups');
}

# appendentity form

sub form_appendentity : Runmode {
	my $self = shift;
	my $tmpl = $self->load_tmpl('Users/form_appendentity.tmpl');
	my $query = $self->query();
	my $egroups = $self->{admin}->getEntity(type => 'Groups', id => $query->param('groups_id'));
	$tmpl->param('groups_id' => $query->param('groups_id'));
	$tmpl->param('groups_name' => $egroups->getAttr('name' => 'groups_name'));
	my $type = $egroups->getAttr('name' => 'groups_type');
	$tmpl->param('groups_type' => $type);
	my $entity_list = [];
	my @entities = $egroups->getExcludedEntities(administrator => $self->{admin});
	
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
	my $egroups = $self->{admin}->getEntity(type => 'Groups', id => $groups_id);
	my $groups_type = $egroups->getAttr('name' => 'groups_type');
	my $entity = $self->{admin}->getEntity(type => $groups_type, id => $real_id);
	$egroups->appendEntity(entity => $entity);
	return $closewindow;
}


# removeentity processing

sub process_removeentity : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $groups_id = $query->param('groups_id');
	my $real_id = $query->param('real_id');
	my $egroups = $self->{admin}->getEntity(type => 'Groups', id => $groups_id);
	my $groups_type = $egroups->getAttr('name' => 'groups_type');
	my $entity = $self->{admin}->getEntity(type => $groups_type, id => $real_id);
	$egroups->removeEntity(entity => $entity);
	$self->redirect("/cgi/mcsui.cgi/users/view_groupdetails?groups_id=$groups_id");
}



1;