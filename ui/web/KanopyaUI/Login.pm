package KanopyaUI::Login;
use base 'CGI::Application';

use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Session;
use Log::Log4perl "get_logger";

use strict;
use warnings;
use Administrator;

my $log = get_logger('webui');

# login form

sub form_login : StartRunmode {
    my $self = shift;
    $self->session_delete;
    my $errors = shift;
    my $tmpl = $self->load_tmpl('login.tmpl');
    $tmpl->param($errors) if $errors;
    return $tmpl->output();
}

# login form processing

sub process_login : Runmode {
	my $self = shift;
	use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_login', '_login_profile');
    return $err_page if $err_page;
	
	my $query = $self->query();
	my $login = $query->param('login');
	my $password = $query->param('password');  
	
	# here we check if login and password match
	eval { Administrator::authenticate(login => $login, password => $password); };
	if($@) { 
		$log->error("Authentication failed for login ", $login);
		$self->redirect('/cgi/kanopya.cgi/login'); 
	} else { 
		$self->session->param('EID', "$ENV{EID}");
		$self->session->param('username', "$login");
		$self->session->flush();
		$log->info("Authentication succeed for login ", $login);
		$self->redirect('/cgi/kanopya.cgi/systemstatus');
	}
}

sub _login_profile {
	return {
    	required => ['login', 'password'],
        msgs => {
        	any_errors => 'some_errors',
            prefix => 'err_'
        },
	};    
}

sub process_logout : Runmode {
	my $self = shift;
	$self->session_delete;
	$log->info("Logout and session delete for login ", $self->session->param('username'));
	$self->redirect('/cgi/kanopya.cgi/login/form_login');
}



1;
