package Users;

use Dancer ':syntax';

use Log::Log4perl "get_logger";
use Entity::User;
use Entity::Gp;

my $log = get_logger('webui');

sub _users {
    
    my @eusers = Entity::User->getUsers(hash => { user_system => 0 });
    my $users = [];
    
    foreach my $user (@eusers) {
        my $tmp = {};
        $tmp->{user_id} = $user->getAttr('name' => 'user_id');
        $tmp->{user_firstname} = $user->getAttr('name' => 'user_firstname'); 
        $tmp->{user_lastname} = $user->getAttr('name' => 'user_lastname');
        
        push(@$users, $tmp);
    }
    
    return $users;
}

sub _userdetails {
    my $user_id = @_;

    my $user_desc;
    my $user_firstname;
    my $user_lastname;
    my $user_email;
    my $user_login;
    my $user_creationdate; 
    my $user_lastaccess;

    my $euser = eval { Entity::User->get(id => $user_id) };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            #$self->{admin}->addMessage(from => 'Administrator', level => 'warning', content => $exception->error);
            #Need to use Dancer's redirect.
            redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
        }
        else {
            $exception->rethrow();
        }
    }
    else {
        $user_desc =  $euser->getAttr('name' => 'user_desc'));
        $user_firstname =  $euser->getAttr('name' => 'user_firstname'));
        $user_lastname =  $euser->getAttr('name' => 'user_lastname'));
        $user_email =  $euser->getAttr('name' => 'user_email'));
        $user_login =  $euser->getAttr('name' => 'user_login'));
        $user_creationdate =  $euser->getAttr('name' => 'user_creationdate'));
        $user_lastaccess =  $euser->getAttr('name' => 'user_lastaccess'));
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
         
        return ($groups,
         $user_desc,          
         $user_firstname,     
         $user_lastname,      
         $user_email,         
         $user_login,         
         $user_creationdate,  
         $user_lastaccess);    
    }
}

get '/users' => sub {
    my $can_create;

    my $methods = Entity::User->getPerms();
    if($methods->{'create'}->{'granted'}) {
        $can_create = 1
    }

    template 'users', {
    titlepage => "Settings - Groups",
    users_list => _users();
    };

};

get '/users/:id' => sub {
    my $can_create;
    my $can_update;
    my $can_delete; 
    my $can_setperm;
    my ($groups,
         $user_desc,          
         $user_firstname,     
         $user_lastname,      
         $user_email,         
         $user_login,         
         $user_creationdate,  
         $user_lastaccess) = _userdetails(params->{id});

    my $euser = eval { Entity::User->get(id => params->{id}) };
    my $methods = $euser->getPerms();
    $log->debug(Dumper $methods);
    if($methods->{'update'}->{'granted'}) { $can_update = 1 }
    if($methods->{'remove'}->{'granted'}) { $can_delete = 1 }
    if($methods->{'setperm'}->{'granted'}) { $can_setperm = 1 }

    }

    template 'users', {
    titlepage => "Users - User details",
    user_id =>  params->{id},
    groups => $groups,        
    user_desc => $user_desc,      
    user_firstname => $user_firstname,
    user_lastname  => $user_lastname, 
    user_email => $user_email, 
    user_login => $user_login, 
    user_creationdate => $user_creationdate,
    user_lastaccess => $user_lastaccess 
    };

};

