package KanopyaUI::Users;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Data::FormValidator::Constraints qw( email FV_eq_with );
use Data::Dumper;
use Log::Log4perl "get_logger";
use Entity::User;
use Entity::Gp;

my $log = get_logger('webui');

# users listing page

sub view_users : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Users/view_users.tmpl');
    $tmpl->param('titlepage' => "Settings - Groups");
    $tmpl->param('mSettings' => 1);
	$tmpl->param('submUsers' => 1);
	$tmpl->param('username' => $self->session->param('username'));
	
	my @eusers = Entity::User->getUsers(hash => { user_system => 0 });
	my $users = [];
	
	foreach my $user (@eusers) {
		my $tmp = {};
		$tmp->{user_id} = $user->getAttr('name' => 'user_id');
		$tmp->{user_firstname} = $user->getAttr('name' => 'user_firstname'); 
		$tmp->{user_lastname} = $user->getAttr('name' => 'user_lastname');
		
		push(@$users, $tmp);
	}
	$tmpl->param('users_list' => $users);
	
	my $methods = Entity::User->getPerms();
	if($methods->{'create'}->{'granted'}) {
		$tmpl->param('can_create' => 1);
	}
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
    my $euser = Entity::User->new( 
	    	user_login => $query->param('login'), 
	    	user_password => $query->param('password'),
	    	user_firstname => $query->param('firstname'),
	    	user_lastname => $query->param('lastname'),
	    	user_email => $query->param('email'),
	    	user_desc => $query->param('desc'),
	);
    eval { $euser->create(); };
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
    
	my $query = $self->query();
	my $user_id = $query->param('user_id');
	my $euser = eval { Entity::User->get(id => $user_id) };
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
		my $tmpl =  $self->load_tmpl('Users/view_userdetails.tmpl');
	    $tmpl->param('titlepage' => "Users - User details");
	    $tmpl->param('mSettings' => 1);
		$tmpl->param('submUsers' => 1);
		$tmpl->param('username' => $self->session->param('username'));
		
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
		my @egroups = Entity::Gp->getGroupsFromEntity(entity => $euser);
		foreach my $eg (@egroups) {
			my $tmp = {};
			$tmp->{gp_id} = $eg->getAttr(name => 'gp_id');
			$tmp->{gp_name} = $eg->getAttr(name => 'gp_name');
			$tmp->{gp_desc} = $eg->getAttr(name => 'gp_desc');
			$tmp->{gp_system} = $eg->getAttr(name => 'gp_system');
			push(@$groups, $tmp);
		} 
		$tmpl->param('gp_list' => $groups);
		
		my $methods = $euser->getPerms();
		$log->debug(Dumper $methods);
		if($methods->{'update'}->{'granted'}) { $tmpl->param('can_update' => 1); }
		if($methods->{'remove'}->{'granted'}) { $tmpl->param('can_delete' => 1); }
		if($methods->{'setperm'}->{'granted'}) { $tmpl->param('can_setperm' => 1); }
			
		return $tmpl->output();
	}
}

# deleteuser processing

sub process_deleteuser : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $user_id = $query->param('user_id');
	# TODO verifier qu'il ne s'agit pas du user qui est loggé
	eval {
		my $euser = Entity::User->get(id => $user_id);
		$euser->delete();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	}
	else { $self->redirect('/cgi/kanopya.cgi/users/view_users'); }
}

# edituser form

sub form_edituser : Runmode {
	return "TODO";
}

1;