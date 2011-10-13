package Permissions;

use Entity::User;
use Entity::Gp;
use Log::Log4perl "get_logger";

my $log = get_logger("webui");

sub _entitys {
	my $entitytype = @_;

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
        $tmp->{entitytype} = 'Gp';
        push @$usersgroups, $tmp;
    }
    
    return ($usersgroups,$users,$groupslist,$entitylist,$entitychoice);

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

get '/selectators/:type' => sub {
    my $entitytype = params->{type};
    my ($usersgroups,$users,
	$groupslist,$entitylist,
	$entitychoice) = _entitys($entitytype);

	template 'selectators', {
    titlepage => "Permissions - who",
    usersgroups => $usersgroups, 
	users => $users,       
	groupslist => $groupslist,  
	entitylist => $entitylist,  
	entitychoice => $entitychoice,
	};
    
};

get '/selectators/:type/:id' => sub {
    my $entitytype = params->{type};
	my $id = params->{id};
    my ($users,$usersgroups) = _selectconsumer($entitytype,$id);

    my $entitymodule = 'Entity/'.$entitytype.'.pm';
    my $entityclass = 'Entity::'.$entitytype;
    eval { require $entitymodule };
    if($@) {
        my $exception = $@;
        $exception->rethrow();
    }
    my $entity = $entityclass->get(id => $id);

	template 'selectators', {
    titlepage => "Permissions",
    usersgroups => $usersgroups, 
	users => $users,       
    entitytype => $entitytype,
    entity_id => $entity->{_entity_id},
    entity_name => $entity->toString(),
	};
    
};

1;
