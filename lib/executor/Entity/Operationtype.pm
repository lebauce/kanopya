#    Copyright © 2012 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

Operation types are used to define the type of an operation, usefull to
defining workflow steps. Entity::Operationtype provides notification subscriptions
that allow to be notified when an operation of a given type change from a
state to another one.

@since    2012-Jun-15
@instance hash
@self     $self

=end classdoc
=cut

package Entity::Operationtype;
use base Entity;

use NotificationSubscription;

use strict;
use warnings;
 
use constant ATTR_DEF => {
    operationtype_name => {
        pattern        => '^.*$',
        is_mandatory   => 1,
        is_extended    => 0,
        is_editable    => 0
    },
    operationtype_label => {
        pattern        => '^.*$',
        is_mandatory   => 1,
        is_extended    => 0,
        is_editable    => 0
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
    };
}


=pod
=begin classdoc

Subscribe to a state change for operations of type $self.
If called on the class, the subscription is about all operation types.

@return the created notification subscription

=end classdoc
=cut

sub subscribe {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args     => \%args,
                         required => [ 'subscriber_id', 'entity_id' ],
                         optional => { 'operation_state' => "processing",
                                       'validation'      => 0 });

    return NotificationSubscription->findOrCreate(
        entity_id           => $args{entity_id},
        subscriber_id       => $args{subscriber_id},
        # If called on the class, subscribe for all operation types
        operationtype_id    => ref($self) ? $self->id : undef,
        operation_state     => $args{operation_state},
        validation          => $args{validation},
    );
}


=pod
=begin classdoc

Remove the given notification subscription.

=end classdoc
=cut

sub unsubscribe {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'notification_subscription_id' ]);

    NotificationSubscription->get(id => $args{notification_subscription_id})->delete();
}

1;
