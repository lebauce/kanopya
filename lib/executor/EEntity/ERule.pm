#    Copyright © 2014 Hedera Technology SAS
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

ERule - Abstract class of Rule object

@since 2012-dec-19

=end classdoc
=cut

package EEntity::ERule;
use base EEntity;

use strict;
use warnings;

use General;

=pod
=begin classdoc

Implement specific notification message

@param operation
@return notification message

=end classdoc
=cut

sub notificationMessage {
    my $self    = shift;
    my %args    = @_;

    General::checkParams(args => \%args, required => [ 'operation', 'state', 'subscriber' ]);

    my $template = Template->new(General::getTemplateConfiguration());
    my $templatedata = {
        rule      => $self->formula_label,
        service   => $self->service_provider->label
        operation => $args{operation}->label
    };

    my $message = '';
    $template->process('rulenotificationmail.tt', $templatedata, \$message)
        or throw Kanopya::Exception::Internal(
             error => "Error when processing template rulenotificationmail.tt"
         );

    my $subject = "";
    $template->process('notificationmailsubject.tt', $templatedata, \$subject)
        or throw Kanopya::Exception::Internal(
             error => "Error when processing template notificationmailsubject.tt"
         );

    return ($subject, $message);
}

1;
