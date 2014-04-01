#    Copyright © 2011-2013 Hedera Technology SAS
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

=pod
=begin classdoc

Entity base class

=end classdoc
=cut

package Entity;
use base BaseDB;

use EntityLock;
use EntityState;
use Entityright;
use EntityComment;
use ClassType;
use Entity::Gp;
use Operationtype;
use Kanopya::Exceptions;
use NotificationSubscription;
use Entity::ServiceProvider::Cluster;

use Data::Dumper;

use TryCatch;

use Log::Log4perl 'get_logger';
my $log = get_logger("");

use constant ATTR_DEF => {
    class_type_id => {
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
    },
    entity_comment_id => {
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
    },
    owner_id => {
        type         => 'relation',
        relation     => 'single',
        is_mandatory => 0,
    },
    entity_time_periods => {
        label        => 'Time periods',
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'time_period',
        is_mandatory => 0,
        is_editable  => 1,
    },
    entity_tags => {
        label        => 'Tags',
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'tag',
        is_mandatory => 0,
        is_editable  => 1,
    },
    comment => {
        is_virtual   => 1,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        subscribe => {
            description => 'subscribe to notification about <object>',
        },
        unsubscribe => {
            description => 'unsubscribe to notification about <object>',
        },
        addPerm => {
            description => 'add a permission for <object>',
        },
        removePerm => {
            description => 'remove a permission for <object>',
        }
    };
}


=pod
=begin classdoc

@constructor

Override BaseDB constructor to add the newly created entity
to the corresponding groups of the whole class hierarchy. 

@return the entity instance

=end classdoc
=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Get the class_type_id for class name
    $args{class_type_id} = ClassType->find(hash => { class_type => $class })->id;

    my $self = $class->SUPER::new(%args);

    # Call the delegatee object to process permissions propagation
    my $delegateeattr = $self->_delegateeAttr;
    if (defined $delegateeattr) {
        $delegateeattr =~ s/_id$//g;
        $self->$delegateeattr->propagatePermissions(related => $self);
    }

    # Try to add the instance to master groups of the whole hierarchy.
    $self->appendToHierarchyGroups(hierarchy => $class);

    return $self;
}


=pod
=begin classdoc

Reload entity from database

@return the reloaded instance

=end classdoc
=cut

sub reload {
    my $self = shift;
    return Entity->get(id => $self->id);
}


=pod
=begin classdoc

Ensure to unlock the entity, whatever the consumer.

=end classdoc
=cut

sub delete {
    my ($self, %args) = @_;

    my $lock = $self->entity_lock_entity;
    if (defined $lock) {
        $self->unlock(consumer => $lock->consumer);
    }
    return $self->SUPER::delete(%args);
}


=pod
=begin classdoc

Override the method to add the promoted object to the groups
of the new hierarchy.

@return the promoted object

=end classdoc
=cut

sub promote {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'promoted' ]);

    # Keep the orignal class of the object
    my $baseclass = ref($args{promoted});

    # Promote it
    my $promoted = $class->SUPER::promote(%args);

    # Extract the new levels of the hierarchy
    my $pattern = $baseclass . '::';
    my $subclass = $class;
    $subclass =~ s/^$pattern//g;

    $promoted->appendToHierarchyGroups(hierarchy => $subclass);

    return $promoted;
}


=pod
=begin classdoc

@return the last set state of the entity

=end classdoc
=cut

sub getState {
    my $self = shift;

    return (defined $self->entity_state) ? $self->entity_state->state : undef;
}


=pod
=begin classdoc

Set the state of the entity, if no consumer defined, use
the entity itself. Consumers are the entities that hace change the state.

=end classdoc
=cut

sub setConsumerState {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'state' ],
                         optional => { 'consumer' => $self });

    my $state;
    try {
        $state = $self->findRelated(filters => [ 'entity_states' ],
                                    hash    => { consumer_id => $args{consumer}->id });
        $state->prev_state($state->state);
        $state->state($args{state});

    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        EntityState->new(entity_id   => $self->id, 
                         consumer_id => $args{consumer}->id,
                         state       => $args{state});
    }
    catch ($err) {
        $err->rethrow();
    }
}


sub removeState {
    my ($self, %args) = @_;
    General::checkParams(args     => \%args,
                         optional => { 'consumer' => $self });

    my $estate;
    try {
        $estate = $self->findRelated(filters => ['entity_states'],
                                     hash    => {consumer_id => $args{consumer}->id});
        $estate->delete();
    }
    catch ($err) {
        # Do not throw exception during state manipulation during cancel
        $log->error('EntityState from entity <'.$self->id.'>, consumer_id <'.$args{consumer}->id.'> not found');
    }
}

=pod
=begin classdoc

Set the state of the entity, if no consumer defined, use
the entity itself. Consumers are the entities that hace change the state.

=end classdoc
=cut

sub restoreState {
    my $self = shift;
    my %args = @_;

    my $state = $self->entity_state;
    if (defined $state) {
        my $current = $state->state;
        $state->setAttr(name => 'state', value => $state->prev_state);
        $state->setAttr(name => 'prev_state', value => $current, save => 1);
    }
}

=pod
=begin classdoc

@return the entity master group

=end classdoc
=cut

sub getMasterGroup {
    my $self = shift;

    try {
        return Entity::Gp->find(hash => { gp_name => $self->getMasterGroupName });
    }
    catch ($er) {
        return Entity::Gp->find(hash => { gp_name => 'Entity' });
    }
}


=pod
=begin classdoc

@return the master group name associated with this entity

=end classdoc
=cut

sub getMasterGroupName {
    my $self = shift;
    my $class = ref $self || $self;
    my @array = split(/::/, "$class");
    my $mastergroup = pop(@array);

    return $mastergroup;
}


sub addPerm {
    my $self = shift;
    my %args = @_;
    my $class = ref $self;

    General::checkParams(args => \%args, required => [ 'method', 'consumer' ]);

    #$log->debug("Add permission on <$self>, for <$args{method}>, to <$args{consumer}>");
    try {
        if ($class) {
            # Consumed is an entity instance
            Entityright->addPerm(
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

            Entityright->addPerm(
                consumer_id => $args{consumer}->id,
                consumed_id => $entity_id,
                method      => $args{method},
            );
        }
    }
    catch (Kanopya::Exception::DB $err) {
        #$log->debug("Permission already exists, skipping.");
    }
    catch ($err) {
        $err->rethrow();
    }
}


sub removePerm {
    my $self = shift;
    my %args = @_;
    my $class = ref $self;

    General::checkParams(args => \%args, required => [ 'method' ], optional => { 'consumer' => undef });

    if ($class) {
        # Consumed is an entity instance
        Entityright->removePerm(
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

        Entityright->removePerm(
            consumer_id => defined $args{consumer} ? $args{consumer}->id : undef,
            consumed_id => $entity_id,
            method      => $args{method},
        );
    }
}

sub checkPerm {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'method', 'user_id' ]);

    try {
        # Check each combination of consumer related ids and
        # consumer ones for the method.
        Entityright->match(consumer_id => $args{user_id},
                           consumed_id => $self->id,
                           method      => $args{method});
    }
    catch ($err) {
        $log->debug($err);
        throw Kanopya::Exception::Permission::Denied(
            error => "No permissions found for user <" . $args{user_id} .
                     ">, on method <$args{method}> of entity <" . $self->id . ">."
        );
    }
}

sub subscribe {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'subscriber_id' ],
                         optional => { 'operationtype'       => undef,
                                       'operation_state'     => "processing",
                                       'service_provider_id' => undef,
                                       'validation'          => 0 });

    if (not defined $args{service_provider_id}) {
        $args{service_provider_id} = Entity::ServiceProvider::Cluster->getKanopyaCluster()->id;
    }

    # If operationtype not defined, subscribe for all operation types
    my $operationtype_id;
    if (defined $args{operationtype}) {
        $operationtype_id = Operationtype->find(hash => { operationtype_name => $args{operationtype} })->id;
    }

    NotificationSubscription->findOrCreate(
        entity_id           => $self->id,
        subscriber_id       => $args{subscriber_id},
        operationtype_id    => $operationtype_id,
        operation_state     => $args{operation_state},
        service_provider_id => $args{service_provider_id},
        validation          => $args{validation},
    );
}

sub unsubscribe {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'notification_subscription_id' ]);

    NotificationSubscription->get(id => $args{notification_subscription_id})->delete();
}


sub activate {
    my $self = shift;

    if (defined $self->ATTR_DEF->{active}) {
        $self->setAttr(name => 'active', value => 1, save => 1);

    } else {
        $errmsg = "Entity->activate Entity ". ref($self) . " unable to activate !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

sub comment {
    my ($self, @args) = @_;

    if (scalar(@args)) {
        return $self->setComment(comment => $args[0]);
    }
    else {
        my $comment_id = $self->getAttr(name => 'entity_comment_id');
        if ($comment_id) {
            return EntityComment->get(id => $comment_id)->getAttr(name => 'entity_comment');
        }
        return '';
    }
}

sub setComment {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'comment' ]);

    my $comment;
    my $comment_id = $self->getAttr(name => 'entity_comment_id');
    if ($comment_id) {
        $comment = EntityComment->get(id => $comment_id);
        $comment->setAttr(name => 'entity_comment', value => $args{comment}, save => 1);
    }
    else {
        $comment = EntityComment->new(entity_comment => $args{comment});
        $self->setAttr(name => 'entity_comment_id', value => $comment->id, save => 1);
    }
}


=pod
=begin classdoc

Append the entity to the groups of the given hierarchy if exists.

=end classdoc
=cut

sub appendToHierarchyGroups {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'hierarchy' ]);

    # Try to add the instance to master groups of the whole hierarchy.
    for my $groupname (reverse(split(/::/, "$args{hierarchy}"))) {
        my $mastergroup;
        try {
            $mastergroup = Entity::Gp->find(hash => { gp_name => $groupname });
            $mastergroup->appendEntity(entity => $self);
        }
        catch (Kanopya::Exception::Internal::NotFound $err) {
            # No master grouyp fr this level of the hierachy
        }
        catch ($err) {
            $err->rethrow();
        }
    }
}


sub lock {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'consumer' ]);

    my $consumer_id = $args{consumer}->id;
    try {
        EntityLock->new(entity_id => $self->id, consumer_id => $consumer_id);
    }
    catch ($err) {
        # Check if the lock is already owned by the workflow
        try {
            EntityLock->find(hash => { entity_id => $self->id, consumer_id => $consumer_id });
            $log->debug($self->class_type->class_type . "<" .
                        $self->id . "> already locked by the consumer <$consumer_id>");
        }
        catch (Kanopya::Exception::Internal::NotFound $err) {
            throw Kanopya::Exception::Execution::Locked(
                      error => $self->class_type->class_type . " <" . $self->id . "> already locked."
                  );
        }
        catch ($err) {
            $err->rethrow();
        }
    }
}

sub unlock {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'consumer' ]);

    try {
        my $lock = EntityLock->find(hash => { entity_id => $self->id, consumer_id => $args{consumer}->id });
        $lock->delete();
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        $log->debug($self->class_type->class_type . "<" .
                    $self->id . "> lock does not exists any more.");
    }
    catch ($err) {
        $err->rethrow();
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


=pod
=begin classdoc

Return the delegatee entity on which the permissions must be checked.
By default, permissions are checked on the entity itself.

@return the delegatee entity.

=end classdoc
=cut

sub _delegatee {
    my $self = shift;

    if (ref($self)) {
        return $self;
    }
    else {
        return $self->getMasterGroup;
    }
}

1;
