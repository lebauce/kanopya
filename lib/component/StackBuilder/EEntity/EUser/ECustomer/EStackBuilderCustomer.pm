#    Copyright © 2011 Hedera Technology SAS
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

The execution class for StackBuilderCustomer;

@since    2014-Apr-18
@instance hash
@self     $self

=end classdoc

=cut

package EEntity::EUser::ECustomer::EStackBuilderCustomer;
use base EEntity;

use strict;
use warnings;

use TryCatch;
use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod
=begin classdoc

Build a notification message with a given Operation

@param operation the operation that is executing
@state the state of the operation

@return notification message

=end classdoc
=cut

sub notificationMessage {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'operation', 'state', 'subscriber' ],
                         optional => { 'reason' => undef });

    my $templatedata = { operation       => $args{operation}->label,
                         operation_id    => $args{operation}->id,
                         workflow        => $args{operation}->workflow->label,
                         workflow_id     => $args{operation}->workflow->id,
                         operation_state => $args{state},
                         reason          => $args{reason},
                         user            => $args{operation}->{context}->{user},
                         stack_id        => $args{operation}->{params}->{stack_id} };

    if (! ($args{operation}->isa('EEntity::EOperation::EConfigureStack') && $args{state} eq "succeeded")) {
        $log->warn("Unsupported tuple user_type/state/operation_type, " .
                   "StackBuilderCustomer/$args{state}/$args{operation}, redirecting to generic notification...");
        return $self->SUPER::notificationMessage(%args);
    }

    my $stackbuilder = $args{operation}->{context}->{stack_builder};
    if (! defined $stackbuilder) {
    	$log->error("Component KanopyaStackBuilder whould be in the operation context, " .
    		        "redirecting to generic notification...");
    	return $self->SUPER::notificationMessage(%args);
    }

    try {
        $templatedata->{access_ip} = $args{operation}->{context}->{novacontroller}->getAccessIp();
        $templatedata->{admin_password} = defined($args{operation}->{params}->{admin_password})
                                        ? $args{operation}->{params}->{admin_password}
                                        : $args{operation}->{context}->{novacontroller}->api_password;
    }
    catch ($err) {
        $log->error("Unable to get the novacontoller access ip for owner notification: $err");
    }

    my $template = Template->new($stackbuilder->getTemplateConfiguration());
    my $templatefile = $stackbuilder->getTemplateDirectory . "/stack-builder-owner-notification-mail";

    my $message = "";
    $template->process($templatefile . '.tt', $templatedata, \$message)
        or throw Kanopya::Exception::Internal(
             error => "Error when processing template " . $templatefile . ".tt"
         );

    my $subject = "";
    $template->process($templatefile . '-subject.tt', $templatedata, \$subject)
        or throw Kanopya::Exception::Internal(
             error => "Error when processing template " . $templatefile . "subject.tt"
         );

    return ($subject, $message);
}


1;
