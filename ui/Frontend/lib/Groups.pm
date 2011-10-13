package Groups;

use Dancer ':syntax';
# Need a Form Validator probably Dancer::Plugin::*
#use Data::FormValidator::Constraints qw( email FV_eq_with );
use Log::Log4perl "get_logger";
use Entity::Gp;

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

sub _groupdetails {
    my $gp_id = shift;
    my $gp_name;
    my $gp_desc;
    my $gp_type;
    my $can_update;
    my $can_delete;
    my $can_appendEntity
    my $content_list;
    my $content_count;
    my $content = [];

    my $egroups = eval { Entity::Gp->get(id => $gp_id) };
#   Need to adapt the following to use Dancer's Permission plugins and such.
    if ( $@ ) {
        my $exception = $@;
        if ( Kanopya::Exception::Permission::Denied->caught() ) {
            my $adm_object = Administrator->new();
            $adm_object->addMessage(
                from    => 'Administrator',
                level   => 'warning',
                content => $exception->error
            );
            # Apply Dancer's redirect in the near future.
            $self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
        }
        else {
            # I don't understand what this is.
            # This needs a better description, and more comments.
            $exception->rethrow();
        }
    }
    else {
        $gp_name =  $egroups->getAttr('name' => 'gp_name');
        $gp_desc =  $egroups->getAttr('name' => 'gp_desc');
        $gp_type =  $egroups->getAttr('name' => 'gp_type');

        my $methods  = $egroups->getPerms();
        my @entities = $egroups->getEntities();
        foreach my $e (@entities) {
            my $tmp = {};

            $tmp->{content_id}       = $e->getAttr('name' => lc($gp_type.'_id'));
            $tmp->{content_label}    = $e->toString();
            $tmp->{gp_id}            = $gp_id;
            $tmp->{can_removeEntity} = $methods->{'removeEntity'}->{'granted'};

            push(@$content, $tmp);
        }

        $content_list  = $content;
        $content_count = scalar(@$content)+1;

        $can_update       = 1 if ( $methods->{'update'}->{'granted'} );
        $can_delete       = 1 if ( $methods->{'remove'}->{'granted'} );
        $can_appendEntity = 1 if ( $methods->{'appendEntity'}->{'granted'} );
    }

    return ($gp_name, $gp_desc, $gp_type, $can_update, $can_delete, $can_appendEntity,
     $content_list, $content_count, $content);
}

get "/groups" => sub {

    my $can_create;
    my $methods = Entity::Gp->getPerms();
    $can_create = 1 if ( $methods->{'create'}->{'granted'} );

    template 'groups', {
        can_create => $can_create,
        title_page => 'Settings - Groups',
        groups     => _groups(),
    };
};

get "/groups/:groupid" => sub {
    # Need to find a more efficient way to run this.
    my ($gp_name, $gp_desc, $gp_type,
    $can_update, $can_delete, $can_appendEntity,
    $content_list, $content_count, $content) = _groupdetails(params->{groupid});

    template 'groupdetail', {
        titlepage        => 'Groups - Group details',
        username         => session('username'),
        gp_id            => params->{groupid},
        gp_name          => $gp_name,
        gp_desc          => $gp_desc,
        gp_type          => $gp_type,
        can_update       => $can_update,
        can_delete       => $can_delete,
        can_appendEntity => $can_appendEntity
        content_list     => $content_list,
        content_count    => $content_count,
        content          => $content,
    };
};


sub form_editgroup {
    return "TODO";
}
