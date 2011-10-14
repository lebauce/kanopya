package Groups;

use Dancer ':syntax';

use Administrator;
use Entity::Gp;

use Log::Log4perl "get_logger";

prefix '/rights';

my $log = get_logger('webui');

sub _groups {
    my @egroups = Entity::Gp->getGroups(hash => { gp_system => 0 });
    my $groups  = [];

    foreach my $group (@egroups) {
        my $tmp = {};
        $tmp->{gp_id}   = $group->getAttr('name' => 'gp_id');
        $tmp->{gp_name} = $group->getAttr('name' => 'gp_name');
        $tmp->{gp_desc} = $group->getAttr('name' => 'gp_desc');
        $tmp->{gp_type} = $group->getAttr('name' => 'gp_type');
        $tmp->{gp_size} = $group->getSize();

        push(@$groups, $tmp);
    }

    return $groups;
}

get '/groups' => sub {
    my $methods = Entity::Gp->getPerms();
    template 'groups', {
        gp_list    => _groups(),
        can_create => $methods->{'create'}->{'granted'}
    };
};

get '/groups/add' => sub {
    template 'form_addgroup', {};
};

post '/groups/add' => sub {
    my $egroup = Entity::Gp->new( 
        gp_name => param('gp_name'), 
        gp_desc => param('gp_desc'),
        gp_type => param('gp_type'),
        gp_system => 0,
    );
    eval { $egroup->create(); };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            my $adm = Administrator->new;
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else { redirect('/rights/groups'); }
};

get '/groups/:groupid/appendentity' => sub {
    my $egroups = Entity::Gp->get(id => param('groupid'));
    my $type = $egroups->getAttr('name' => 'gp_type');
    my $entity_list = [];
    my @entities = $egroups->getExcludedEntities();
    
    foreach my $e (@entities) {
        my $tmp = {};
        $tmp->{real_id} = $e->getAttr(name => lc($type)."_id");
        $tmp->{entity_label} = $e->toString();
        push(@$entity_list, $tmp);
    }

    template 'form_appendentity', {
        gp_id       => param('groupid'),
        gp_name     => $egroups->getAttr('name' => 'gp_name'),
        gp_type     => $egroups->getAttr('name' => 'gp_type'),
        entity_list => $entity_list
    };
};

post '/groups/:groupid/appendentity' => sub {
    my $gp_id = param('groupid');
    my $real_id = param('real_id');
    my $egroups = Entity::Gp->get(id => $gp_id);
    my $gp_type = $egroups->getAttr('name' => 'gp_type');
    my $module = "Entity/".$gp_type.".pm";
    my $class = "Entity::".$gp_type;
    eval { require $module; };
    my $entity = $class->get(id => $real_id);
    $egroups->appendEntity(entity => $entity);
    redirect('/rights/groups/'.param('groupid'));
};

get '/groups/:groupid/remove/:entityid' => sub {
    my $gp_id = param('groupid');
    my $real_id = param('entityid');
    my $egroups = Entity::Gp->get(id => $gp_id);
    my $gp_type = $egroups->getAttr('name' => 'gp_type');
    my $module = "Entity/".$gp_type.".pm";
    my $class = "Entity::".$gp_type;
    eval { require $module; };
    my $entity = $class->get(id => $real_id);
    $egroups->removeEntity(entity => $entity);
    redirect('/rights/groups/'.$gp_id);
};

get '/groups/:groupid' => sub {
    my $egroups = eval { Entity::Gp->get(id => param('groupid')) };
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

    my @entities = $egroups->getEntities();
    my $content_list = [];
    foreach my $e (@entities) {
        my $tmp = {};
        $tmp->{content_id} = $e->getAttr('name' => lc($egroups->getAttr('name' => 'gp_type')).'_id');
        $tmp->{content_label} = $e->toString();
        $tmp->{gp_id} = params->{groupid};
                    
        push(@$content_list, $tmp) 
    }

    my $methods = $egroups->getPerms();

    template 'groups_details', {
        titlepage        => 'Groups - Group details',
        username         => session('username'),
        gp_id            => params->{groupid},
        gp_name          => $egroups->getAttr('name' => 'gp_name'),
        gp_desc          => $egroups->getAttr('name' => 'gp_name'),
        gp_type          => $egroups->getAttr('name' => 'gp_type'),
        content_list     => $content_list,
        content_count    => scalar(@$content_list)+1,
        can_update       => $methods->{'update'}->{'granted'},
        can_delete       => $methods->{'remove'}->{'granted'},
        can_appendEntity => $methods->{'appendEntity'}->{'granted'},
        can_removeEntity => $methods->{'removeEntity'}->{'granted'}
    };
};


1;
