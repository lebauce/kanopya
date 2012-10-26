package Entity;
use base 'BaseDB';

use Data::Dumper;
use Log::Log4perl 'get_logger';

use EntityLock;
use EntityComment;
use Entity::Workflow;
use Message;
use Entity::Gp;
use OperationParameter;
use Operationtype;
use Kanopya::Exceptions;
use Entity::Operation;
use NotificationSubscription;

my $log = get_logger("");

use constant ATTR_DEF => {
    class_type_id => {
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    entity_comment_id => {
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        subscribe => {
            description => 'subscribe to notification about this entity.',
            perm_holder => 'entity'
        }
    };
}

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

=head2

    Lock the entity while updating it.

=cut

sub update {
    my ($self, %args) = @_;

    # Try to lock the entoty while updating it
    $self->lock(consumer => $self);

    $self->SUPER::update(%args);

    $self->unlock(consumer => $self);
    return $self;
}

=head2

    Ensure to get the lock on the entity before removing it.

=cut

sub remove {
    my ($self, %args) = @_;

    # Try to lock the entoty while updating it
    $self->lock(consumer => $self);

    $self->SUPER::remove(%args);

    $self->unlock(consumer => $self);
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
            $granted = $adm->getRightChecker->checkPerm(entity_id => $self->id, method => $m);
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

=head2 subscribe

=cut

sub subscribe {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'subscriber_id', 'operationtype' ],
                         optional => { 'service_provider_id' => 1,
                                       'validation'          => 0 });

    my $operationtype = Operationtype->find(hash => { operationtype_name => $args{operationtype} });
    NotificationSubscription->new(
        entity_id           => $self->id,
        subscriber_id       => $args{subscriber_id},
        operationtype_id    => $operationtype->id,
        service_provider_id => $args{service_provider_id},
        validation          => $args{validation},
    );
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
    }
    else {
        $comment = EntityComment->new(entity_comment => $args{comment});
        $self->setAttr(name => 'entity_comment_id', value => $comment->getAttr(name => 'entity_comment_id'));
        $self->save();
    }
}


sub lock {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'consumer' ]);

    my $consumer_id = $args{consumer}->id;
    eval {
        EntityLock->new(entity_id => $self->id, consumer_id => $consumer_id);
    };
    if ($@) {
        # Check if the lock is already owned by the workflow
        my $lock;
        eval {
            $lock = EntityLock->find(hash => {
                        entity_id   => $self->id,
                        consumer_id => $consumer_id,
                    });
        };
        if (not $lock) {
            throw Kanopya::Exception::Execution::Locked(
                      error => "Entity <" . $self->id . "> already locked."
                  );
        } else {
            $log->debug("Entity <" . $self->id . "> already locked by the consumer <$consumer_id>");
        }
    }
}

sub unlock {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'consumer' ]);

    my $lock;
    eval {
        $lock = EntityLock->find(hash => {
                    entity_id   => $self->id,
                    consumer_id => $args{consumer}->id,
                });
    };
    if ($@) {
        my $error = $@;
        if ($error->isa('Kanopya::Exception::Internal::NotFound')) {
            $log->debug("Entity <" . $self->id . "> lock does not exists any more.");
        }
        else { throw $error; }
    }
    else {
        $lock->delete();
    }
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
    my $self  = shift;
    my $class = ref $self;
    my %args  = @_;

    my $adm = Administrator->new();

    General::checkParams(args => \%args, required => [ 'method' ], optional => { 'params' => {} });

    my $methods = $self->getMethods();

    # Retreive the perm holder if it is not a method cal on a entity (usally class methods)
    my ($granted, $perm_holder_id);
    if ($methods->{$args{method}}->{perm_holder} eq 'mastergroup') {
        $perm_holder_id = $self->getMasterGroup->id;
    }
    elsif ($class and $methods->{$args{method}}->{perm_holder} eq 'entity') {
        $perm_holder_id = $self->id;
    }

    # Check the permissions for the logged user
    $granted = $adm->getRightChecker->checkPerm(entity_id => $perm_holder_id, method => $args{method});
    if (not $granted) {
        my $msg = "Permission denied to " . $methods->{$args{method}}->{description};
        throw Kanopya::Exception::Permission::Denied(error => $msg);
    }

    return $self->SUPER::methodCall(%args);
}

1;
