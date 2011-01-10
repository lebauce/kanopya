package KanopyaUI::Users;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Data::FormValidator::Constraints qw( email FV_eq_with );
use Data::Dumper;
use Log::Log4perl "get_logger";
use Entity::User;
use Entity::Groups;

my $log = get_logger('administrator');

my $closewindow = "<script type=\"text/javascript\">window.opener.location.reload();window.close();</script>";

# users listing page

sub view_users : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Users/view_users.tmpl');
    $tmpl->param('titlepage' => "Settings - Groups");
    $tmpl->param('mSettings' => 1);
	$tmpl->param('submUsers' => 1);
	
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
    	user_creationdate => \"NOW()",
    	user_lastaccess => undef
    );
    $euser->save();
    # TODO add initial permission for this user
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
	my $euser = Entity::User->get(id => $user_id);
	
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
	my @egroups = Entity::Groups->getGroupsFromEntity(entity => $euser);
	foreach my $eg (@egroups) {
		my $tmp = {};
		$tmp->{groups_id} = $eg->getAttr(name => 'groups_id');
		$tmp->{groups_name} = $eg->getAttr(name => 'groups_name');
		$tmp->{groups_desc} = $eg->getAttr(name => 'groups_desc');
		$tmp->{groups_system} = $eg->getAttr(name => 'groups_system');
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
	my $euser = Entity::User->get(id => $user_id);
	$euser->delete();
	# TODO retirer le user des groups auquels il appartient
	# TODO supprimer tous les droits du user 
	$self->redirect('/cgi/kanopya.cgi/users/view_users');
}


1;