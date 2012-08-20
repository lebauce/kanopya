package Entity;
use base 'BaseDB';

use Data::Dumper;
use Log::Log4perl 'get_logger';

use EntityLock;
use EntityComment;
use Workflow;
use Message;
use Entity::Gp;
use OperationParameter;
use Kanopya::Exceptions;
use Entity::Operation;

my $log = get_logger('administrator');

use constant ATTR_DEF => {
    class_type_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    entity_comment_id => {
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};


sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        getWorkflows => {
            description => 'getWorkflows',
            perm_holder => 'entity'
        }
    };
}

sub primarykey { return 'entity_id'; }

=head2 getMasterGroupName

    Override BaseDB constructor to add the newly created entity
    to the corresponding group. 

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    $class->getMasterGroup->appendEntity(entity => $self);
    return $self;
}

=head2 getMasterGroup

    Class : public

    desc : return entity_id of entity master group
    TO BE CALLED ONLY ON CHILD CLASS/INSTANCE
    return : scalar : entity_id

=cut

sub getMasterGroup {
    my $self = shift;

    my $group;
    eval {
        $group = Entity::Gp->find(hash => { gp_name => $self->getMasterGroupName });
    };
    if ($@) {
        $group = Entity::Gp->find(hash => { gp_name => $self->getGenericMasterGroupName });
    }
    return $group;
}

=head2 getMasterGroupName

    Class : public
    desc : retrieve the master group name associated with this entity
    return : scalar : master group name

=cut

sub getMasterGroupName {
    my $self = shift;
    my $class = ref $self || $self;
    my @array = split(/::/, "$class");
    my $mastergroup = pop(@array);
    return $mastergroup;
}

=head2 getGenericMasterGroupName

    Get an alternative group name if the correponding group 
    of the concrete class of the entity do not exists.

=cut

sub getGenericMasterGroupName {
    my $self = shift;
    return 'Entity';
}

sub asString {
    my $self = shift;

    my %h = $self->getAttrs;
    my @s = map { "$_ => $h{$_}, " } keys %h;
    return ref $self, " ( ",  @s,  " )";
}

=head2 getPerms

    class : public

    desc : return a structure describing method permissions for the current authenticated user.
        If called on a class, return methods permissions holded by mastergroup only.
        Else return all methods permissions.

    return : hash ref

=cut

sub getPerms {
    my $self = shift;
    my $class = ref $self;
    my $adm = Administrator->new();
    my $mastergroupeid = $self->getMasterGroup->id;
    my $methods = $self->methods();
    my $granted;

    foreach my $m (keys %$methods) {
        if($methods->{$m}->{'perm_holder'} eq 'mastergroup') {
            $granted = $adm->getRightChecker->checkPerm(entity_id => $mastergroupeid, method => $m);
            $methods->{$m}->{'granted'} = $granted;
        }
        elsif($class and $methods->{$m}->{'perm_holder'} eq 'entity') {
            $granted = $adm->getRightChecker->checkPerm(entity_id => $self->{_entity_id}, method => $m);
            $methods->{$m}->{'granted'} = $granted;
        }
        else {
            delete $methods->{$m};
        }
    }
    #$log->debug(Dumper $methods);
    return $methods;
}

=head2 addPerm

=cut

sub addPerm {
    my $self = shift;
    my %args = @_;
    my $class = ref $self;

    General::checkParams(args => \%args, required => [ 'method', 'consumer' ]);

    my $adm = Administrator->new();

    if ($class) {
        # Consumed is an entity instance
        $adm->getRightChecker->addPerm(
            consumer_id => $args{consumer}->id,
            consumed_id => $self->id,
            method      => $args{method},
        );
    }
    else {
        # Consumed is an entity type
        my @list = split(/::/, "$self");
        my $mastergroup = pop(@list);
        my $entity_id = Entity::Gp->find(hash => { gp_name => $mastergroup })->id;

        $adm->getRightChecker->addPerm(
            consumer_id => $args{consumer}->id,
            consumed_id => $entity_id,
            method      => $args{method},
        );
    }
}

=head2 removePerm

=cut

sub removePerm {
    my $self = shift;
    my %args = @_;
    my $class = ref $self;

    General::checkParams(args => \%args, required => [ 'method' ], optional => { 'consumer' => undef });

    my $adm = Administrator->new();

    if ($class) {
        # Consumed is an entity instance
        $adm->getRightChecker->removePerm(
            consumer_id => defined $args{consumer} ? $args{consumer}->id : undef,
            consumed_id => $self->id,
            method      => $args{method},
        );
    }
    else {
        # Consumed is an entity type
        my @list = split(/::/, "$self");
        my $mastergroup = pop(@list);
        my $entity_id = Entity::Gp->find(hash => { gp_name => $mastergroup })->id;

        $adm->getRightChecker->removePerm(
            consumer_id => defined $args{consumer} ? $args{consumer}->id : undef,
            consumed_id => $entity_id,
            method      => $args{method},
        );
    }
}

sub activate {
    my $self = shift;

    if (defined $self->ATTR_DEF->{active}) {
        $self->{_dbix}->update({active => "1"});
#        $self->setAttr(name => 'active', value => 1);
        $log->debug("Entity::Activate : Entity is activated");
    } else {
        $errmsg = "Entity->activate Entity ". ref($self) . " unable to activate !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub getEntities {
    my $class = shift;
    my %args = @_;
    my @objs = ();
    my ($rs, $entity_class);

    General::checkParams(args => \%args, required => ['type', 'hash']);

    my $adm = Administrator->new();

    $rs = $adm->_getDbixFromHash( table => $args{type}, hash => $args{hash} );
    $log->debug( "_getEntityClass with type = $args{type}");

    my $id_name = lc($args{type}) . "_id";
    $entity_class = "Entity::$args{type}";

    while ( my $row = $rs->next ) {
        my $id = $row->get_column($id_name);
        my $obj = eval { $entity_class->get(id => $id); };
        if($@) {
            my $exception = $@;
            if (Kanopya::Exception::Permission::Denied->caught()) {
                $log->info("no right to access to object <$args{type}> with  <$id>");
                next;
            }
            else { $exception->rethrow(); }
        }
        else { push @objs, $obj; }
    }
    return  @objs;
}

sub getId() {
    my $self = shift;

    return $self->getAttr(name => "entity_id");
}

sub getComment {
    my $self = shift;

    my $comment_id = $self->getAttr(name => 'entity_comment_id');
    if ($comment_id) {
        return EntityComment->get(id => $comment_id)->getAttr(name => 'entity_comment');
    }
    return '';
}

sub setComment {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'comment' ]);

    my $comment;
    my $comment_id = $self->getAttr(name => 'entity_comment_id');
    if ($comment_id) {
        $comment = EntityComment->get(id => $comment_id);
        $comment->setAttr(name => 'entity_comment', value => $args{comment});
        $comment->save();
        $log->info($comment);
    }
    else {
        $comment = EntityComment->new(entity_comment => $args{comment});
        $self->setAttr(name => 'entity_comment_id', value => $comment->getAttr(name => 'entity_comment_id'));
        $self->save();
    }

    $log->info($comment);
}

sub getWorkflows {
    my $self = shift;
    my %args = @_;

    my @workflows = ();

    # TODO: join tables workflow and workflow_parameter to get
    #       paramters of running workflow only.
    my @contexes = OperationParameter->search(hash => {
                       tag   => 'context',
                       value => $self->getId
                   });

    for my $context (@contexes) {
        my $workflow = Entity::Operation->get(id => $context->getAttr(name => 'operation_id'))->getWorkflow;
        if ($workflow->getAttr(name => 'state') eq 'running') {
            push @workflows, $workflow;
        }
    }
    return wantarray ? @workflows : \@workflows;
}

sub lock {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'workflow' ]);

    my $workflow_id = $args{workflow}->getAttr(name => 'workflow_id');
    eval {
        EntityLock->new(entity_id => $self->getId, workflow_id => $workflow_id);
    };
    if ($@) {
        # Check if the lock is already owned by the workflow
        my $lock;
        eval {
            $lock = EntityLock->find(hash => { entity_id   => $self->getId(),
                                               workflow_id => $workflow_id });
        };
        if (not $lock) {
            throw Kanopya::Exception::Execution::Locked(
                      error => "Entity <" . $self->getId . "> already locked."
                  );
        }
    }
}

sub unlock {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'workflow' ]);

    my $lock = EntityLock->find(hash => {
                   entity_id   => $self->getId(),
                   workflow_id => $args{workflow}->getAttr(name => 'workflow_id')
               });

    $lock->delete();
}

sub getAttr {
    my $self = shift;
    my %args = @_;

    if ($args{name} eq "comment") {
        return $self->getComment();
    }
    else {
        return $self->SUPER::getAttr(%args);
    }
}

sub setAttr {
    my $self = shift;
    my %args = @_;

    if ($args{name} eq "comment") {
        $self->setComment(comment => $args{value});
    }
    else {
        $self->SUPER::setAttr(%args);
    }
}

sub toJSON {
    my ($self, %args) = @_;
    my $class = ref $self || $self;
    my $hash = $self->SUPER::toJSON(%args);

    if (ref $self) {
        $hash->{pk} = $self->getAttr(name => "entity_id");
    }
    else {
        $hash->{pk} = {
            pattern      => '^\d*$',
            is_mandatory => 1,
            is_extended  => 0
        }
    }
    return $hash;
}

=head2

    It is convenient to override this method in Entity,
    for centralizing permmissions checking.

=cut

sub methodCall {
    my $self = shift;
    my $class = ref $self;
    my %args = @_;

    my $adm = Administrator->new();

    General::checkParams(args => \%args, required => [ 'method' ], optional => { 'params' => {} });

    my $methods = $self->getMethods();

    # Retreive the perm holder if it is not a method cal on a entity (usally class methods)
    my ($granted, $perm_holder);
    if ($methods->{$args{method}}->{perm_holder} eq 'mastergroup') {
        $perm_holder = $self->getMasterGroup;
    }
    elsif ($class and $methods->{$args{method}}->{perm_holder} eq 'entity') {
        $perm_holder = $self;
    }

    # Check the permissions for the logged user
    $granted = $adm->getRightChecker->checkPerm(entity_id => $perm_holder->id, method => $args{method});
    if (not $granted) {
        my $msg = "Permission denied to " . $methods->{$args{method}}->{description};
        Message->send(
            from    => 'Permissions checker',
            level   => 'error',
            content => $msg
        );
        throw Kanopya::Exception::Permission::Denied(error => $msg);
    }

    return $self->SUPER::methodCall(%args);
}

1;
