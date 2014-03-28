#    Copyright © 2011-2014 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod
=begin classdoc

@since    2014-March-26
@instance hash
@self     $self

=end classdoc
=cut

package MailNotifier;
use base Daemon::MessageQueuing;

use strict;
use warnings;

use Entity::User;

use TryCatch;

use Log::Log4perl "get_logger";
use Log::Log4perl::Layout;
use Log::Log4perl::Appender;

my $log = get_logger("");

use constant CALLBACKS => {
    mail_notification => {
        callback  => \&notify,
        type      => 'queue',
        queue     => 'kanopya.mailnotifier.notification',
        duration  => 30,
    },
};

sub getCallbacks { return CALLBACKS; }


=pod
=begin classdoc

@constructor

Instanciate a mail notifier daemon.

@return the mail notifier instance

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(confkey => 'mail-notifier', %args);

    if (! (defined ($self->_component) && $self->_component->isa("Entity::Component"))) {
        throw Kanopya::Exception::Daemon(
                  error => "Corresponding component KanopyaMailNotifer not found, can not continue."
              );
    }
    return $self;
}


=pod
=begin classdoc

Wait messages on the queue 'kanopya.mailnotifier.notification',
send the mail to the subscriber with given buject and content.

@param user the destination user a the notification
@param message the message content

@optional subject the subject of the notification

=end classdoc
=cut

sub notify {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ "user_id", "message" ],
                         optional => { "subject" => "" });

    $args{user} = Entity::User->get(id => delete $args{user_id});

    # Propagate the call to the execution mail notifier
    try {
        EEntity->new(data => $self->_component)->notify(%args);
    }
    catch ($err) {
        $log->error("Unable to notify user " . $args{user}->user_login . ": $err");

        # Do not ack the message to avoid loosing the mail
        return 0;
    }

    # Acknowledge the message
    return 1;
}

1;
