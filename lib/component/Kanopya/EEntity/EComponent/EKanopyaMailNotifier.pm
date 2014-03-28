# Copyright © 201 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.


=pod
=begin classdoc

TODO

=end classdoc
=cut

package EEntity::EComponent::EKanopyaMailNotifier;
use base "EEntity::EComponent";
use base "EManager::ENotificationManager";

use strict;
use warnings;

use Net::SMTP;
use Net::SMTP::SSL;

use Log::Log4perl "get_logger";
use Data::Dumper;
use TryCatch;

my $log = get_logger("");
my $errmsg;


=pod
=begin classdoc

Notifiy the user by mail

@param user User instance
@param message String Email message
@optional String Email subject

=end classdoc
=cut

sub notify {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "user", "message" ],
                         optional => { "subject" => "" });

    my $params = {
        Timeout => 30,
        Debug   => 1,
    };

    # If ssl activated, use the corresponding module.
    my $smtpclass;
    if ($self->use_ssl) {
        $smtpclass = "Net::SMTP::SSL";
        $params->{Port} = 465;

    } else {
        $smtpclass = "Net::SMTP";
    }

    $log->debug("Connecting to the smtp server <" . $self->smtp_server . ">, params: " . Dumper($params));

    # Connect to the smtp server
    my $smtp = $smtpclass->new($self->smtp_server, %$params);
    if (defined $smtp) {
        try {
            # If credentials defined, use authentication
            if ($self->smtp_login) {
                $smtp->auth($self->smtp_login, $self->smtp_passwd);
            }

            # Set the sender and receiver
            $smtp->mail($self->smtp_login);
            $smtp->to($args{user}->user_email);

            $log->info("Sending mail, To: " . $args{user}->user_email . ", From: " . $self->smtp_login,
                       ", Subject: " . $args{subject});
            $log->debug("Message:\n" . $args{message});

            # Set the mail contents
            $smtp->data();
            $smtp->datasend("To: " . $args{user}->user_email . "\n");
            $smtp->datasend("From: " . $self->smtp_login . "\n");
            $smtp->datasend("Subject: " . $args{subject} . "\n");
            $smtp->datasend("\n");

            $smtp->datasend($args{message});
            $smtp->dataend();

            # Close the smtp connection
            $smtp->quit;
        }
        catch ($err) {
            throw Kanopya::Exception::Execution(
                      error => "Unable to send mail to " . $args{user}->user_email . ":$err"
                  );
        }
    }
    else {
        $log->warn("Can not connect to smtp server <" . $self->smtp_server . ">");
    }
}

1;
