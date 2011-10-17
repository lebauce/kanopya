package Permissions;

use Dancer ':syntax';

use Administrator;
use Entity::User;
use Entity::Gp;
use Log::Log4perl "get_logger";

prefix '/rights';

my $log = get_logger("webui");

my @entity_types = qw/Motherboardmodel Processormodel Cluster
                        Motherboard Systemimage Distribution Kernel
                        User/;

sub _types_list {
    my $selected = shift;
    my $list = [];
    if($selected) {
        if(!scalar(grep(/$selected/, @entity_types))) {
            redirect('/rights/permissions');
        }
    }

    foreach my $entity (@entity_types) {
        my $tmp = {};
        $tmp->{name} = $entity;
        $tmp->{selected} = 'selected' if $selected eq $entity;
        push(@$list, $tmp);
    }
    return $list;
}

sub _groups_list {
    my $entity_type = shift;
    my @egroups = Entity::Gp->getGroups(hash => {gp_type => $entity_type});
    my $groups_list = [];
    foreach my $e (@egroups) {
        my $tmp = {};
        $tmp->{entity_id} = $e->{_entity_id};
        $tmp->{groups} = $e->toString();
        $tmp->{entitytype} = 'Gp';
        push @$groups_list, $tmp;
    }
    return $groups_list;
}

sub _entities_list {
    my ($entitytype, $selected) = @_;
    my $entitymodule = 'Entity/'.$entitytype.'.pm';
    my $entityclass = 'Entity::'.$entitytype;
    eval { require $entitymodule };
    if($@) {
        my $exception = $@;
        $exception->rethrow();
    }
    
    my @entities = $entityclass->getEntities(hash => {}, type => $entitytype);
    my $entitylist = [];
    foreach my $e (@entities) {
        my $tmp = {};
        $tmp->{selected} = 'selected' if $selected eq $e->getAttr('name' => lc($entitytype).'_id');
        $tmp->{entity_id} = $e->{_entity_id};
        $tmp->{entity} = $e->toString();
        $tmp->{entitytype} = $entitytype;
        push @$entitylist, $tmp;
    }
    return $entitylist;
}

sub _users_list {
    my @eusers = Entity::User->getUsers(hash => {user_system => 0});
    my $users = [];
    foreach my $u (@eusers) {
        my $tmp = {};
        $tmp->{entity_id} = $u->{_entity_id};
        $tmp->{user} = $u->toString();
        $tmp->{entitytype} = 'User';
        push @$users, $tmp;
    }
    return $users;
}

sub _selectconsumer {
    my ($entitytype,$id) = @_;
    
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
    
    return ($users,$usersgroups);
}

get '/permissions' => sub {

    template 'permissions', {
        entity_types_list => _types_list()
    };
};

get '/permissions/:type' => sub {
    my $type = ucfirst(param('type'));
    template 'permissions', {
        entity_types_list => _types_list($type),
        groups_list       => _groups_list($type),
        entities_list     => _entities_list($type),
        entitytype        => $type,
        usersgroups_list  => _groups_list('User'),
        users_list        => _users_list(),
    };
};

get '/permissions/:type/:id' => sub {
    my $type = ucfirst(param('type'));
    template 'permissions', {
        entity_types_list => _types_list($type),
        groups_list       => _groups_list($type),
        entities_list     => _entities_list($type, param('id')),
        entitytype        => $type,
        usersgroups_list  => _groups_list('User'),
        users_list        => _users_list(),
    };
};

get '/permissions/set/:consumertype/:consumerid/:consumedtype/:consumedid' => sub {
    my $adm = Administrator->new;
    my $consumertype = param('consumertype');
    my $consumedtype = param('consumedtype');

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
    my @grantedmethods = $adm->{_rightchecker}->getGrantedMethods(
        consumer_id => param('consumerid'),
        consumed_id => param('consumedid'),
    );

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

    template 'form_permissionsettings', {
        methods       => $methodlist,
        consumer_id   => param('consumerid'),
        consumed_id   => param('consumedid'),
        consumed_type => param('consumedtype'),
    };
};

post '/permissions/set' => sub {
    my $adm = Administrator->new;
    my @methods = param('methods');
    $adm->{'_rightchecker'}->updatePerms(
        consumer_id => param('consumer_id'),
        consumed_id => param('consumed_id'),
        methods => \@methods
    );
};

1;
