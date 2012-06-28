package Users;

use Dancer ':syntax';

use Log::Log4perl "get_logger";
use Administrator;
use Entity::User;
use Entity::Gp;
use Entity::ServiceProvider::Inside::Cluster;
use Data::Dumper;

prefix '/rights';

my $log = get_logger('webui');

sub _users {

    my @eusers = Entity::User->getUsers(hash => { user_system => 1 });
    my $users = [];

    foreach my $user (@eusers) {
        my $tmp = {};

        $tmp->{user_id}        = $user->getAttr('name' => 'user_id');
        $tmp->{user_firstname} = $user->getAttr('name' => 'user_firstname');
        $tmp->{user_lastname}  = $user->getAttr('name' => 'user_lastname');

        push(@$users, $tmp);
    }

    return $users;
}

get '/users' => sub {
    my $methods = Entity::User->getPerms();
    template 'users', {
        users_list => _users(),
        can_create => $methods->{'create'}->{'granted'}
    };
};

get '/users/add' => sub {
    template 'form_adduser', {}, { layout => '' };
};

post '/users/add' => sub {
    my $adm = Administrator->new;
    my $euser = Entity::User->new( 
            user_login => param('login'), 
            user_password => param('password'),
            user_firstname => param('firstname'),
            user_lastname => param('lastname'),
            user_email => param('email'),
            user_desc => param('desc'),
    );
    eval { $euser->create(); };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else { redirect('/rights/users'); }
};

get '/users/:userid/delete' => sub {
    my $adm = Administrator->new();

    eval {
        my $euser = Entity::User->get( id => params->{userid} );
        $euser->delete();
    };
    if ( $@ ) {
        my $exception = $@;
        if ( Kanopya::Exception::Permission::Denied->caught() ) {
           $adm->addMessage(
               from    => 'Administrator',
               level   => 'error',
               content => $exception->error
           );

           redirect '/permission_denied';
        }
        else {
            $exception->rethrow();
        }
    }
    else {
        redirect '/rights/users';
    }
};

get '/users/:userid' => sub {
    my $user_id = param('userid');
    my $euser = eval { Entity::User->get(id => $user_id) };
    my @cluster = Entity::ServiceProvider::Inside::Cluster->getClusters( hash => { user_id => $user_id } );
    my $clusters = [];
    foreach my $ec (@cluster)
    {
		my $cluster_id= $ec->getAttr(name => 'cluster_id');
		my $tmpc = {};
        $tmpc->{cluster_name}     = $ec->getAttr(name => 'cluster_name');
        $tmpc->{url}        = "http://10.0.0.1:5000/architectures/clusters/$cluster_id";
        
         push(@$clusters, $tmpc);
	}
    
       if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            my $adm = Administrator->new;
            $adm->addMessage(from => 'Administrator', level => 'warning', content => $exception->error);
            redirect('/permission_denied');
        }
        else {
            $exception->rethrow();
        }
    }
    
    my $groups = [];
    my @egroups = Entity::Gp->getGroupsFromEntity(entity => $euser);
    foreach my $eg (@egroups) {
        my $tmp = {};
        $tmp->{gp_id}     = $eg->getAttr(name => 'gp_id');
        $tmp->{gp_name}   = $eg->getAttr(name => 'gp_name');
        $tmp->{gp_desc}   = $eg->getAttr(name => 'gp_desc');
        $tmp->{gp_system} = $eg->getAttr(name => 'gp_system');
        push(@$groups, $tmp);
    } 
    
    my $methods = $euser->getPerms();
    
    template 'users_details', {
        user_id           => $euser->getAttr('name' => 'user_id'),
        user_desc         => $euser->getAttr('name' => 'user_desc'),
        user_firstname    => $euser->getAttr('name' => 'user_firstname'),
        user_lastname     => $euser->getAttr('name' => 'user_lastname'),
        user_email        => $euser->getAttr('name' => 'user_email'),
        user_login        => $euser->getAttr('name' => 'user_email'),
        user_creationdate => $euser->getAttr('name' => 'user_creationdate'),
        user_lastaccess   => $euser->getAttr('name' => 'user_lastaccess'),
        gp_list           => $groups,
        clusters_list     => $clusters,
        can_update        => $methods->{'update'}->{'granted'},
        can_delete        => $methods->{'remove'}->{'granted'},
        can_setperm       => $methods->{'setperm'}->{'granted'},
    };
};

1;
