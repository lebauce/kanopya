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

Kanopya Exceptions declaration

Exception description message can be templated with fields.
Warning a field 'error' in Exception replaces the templated message.

@since 2011-Jan-13

=end classdoc
=cut

package Kanopya::Exceptions;

use Template;

use Exception::Class (
    Kanopya::Exception => {
        description => "Kanopya General Exception",
        fields      => [ 'level', 'request', 'hidden' ],
    },
    Kanopya::Exception::DB => {
        isa         => 'Kanopya::Exception',
        description => 'Kanopya Database exception>',
        fields      => [ 'label' ],
    },
    Kanopya::Exception::DB::DuplicateEntry => {
        isa         => 'Kanopya::Exception::DB',
        description => 'Creation of a new instance of class <[% class %]> impossible: '
                       . 'an instance with value <[% entry %]> for <[% key %]> already exists',
        fields      => [ 'class', 'key', 'entry'],
    },
    Kanopya::Exception::DB::DeleteCascade => {
        isa         => 'Kanopya::Exception::DB',
        description => 'Deletion of <[% label %]> is impossible: it is used by a <[% dependant %]>.',
        fields      => [ 'dependant' ],
    },
    Kanopya::Exception::DB::ForeignKeyConstraint => {
        isa         => 'Kanopya::Exception::DB',
        description => 'A foreign key constraint triggered an exception',
        fields      => [ ],
    },
    Kanopya::Exception::DB::UnknownSource => {
        isa         => 'Kanopya::Exception::DB',
        description => 'Unknown database source',
    },
    Kanopya::Exception::IO => {
        isa         => 'Kanopya::Exception',
        description => 'Kanopya IO exception',
    },
    Kanopya::Exception::Network => {
        isa         => 'Kanopya::Exception',
        description => 'SSH communication exception',
    },
    Kanopya::Exception::Quota => {
        isa         => 'Kanopya::Exception',
        description => 'Quota exceeded',
    },
    Kanopya::Exception::Method => {
        isa         => 'Kanopya::Exception',
        description => 'Can\'t call method on class',
    },
    Kanopya::Exception::UnkonwnMethod => {
        isa         => 'Kanopya::Exception',
        description => 'Unkonwn method',
    },
    Kanopya::Exception::Internal => {
        isa         => 'Kanopya::Exception',
        description => 'Kanopya Internal exception',
    },
    Kanopya::Exception::Internal::WrongValue => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Wrong Value',
    },
    Kanopya::Exception::Internal::WrongType => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Wrong Type',
    },
    Kanopya::Exception::Internal::NotFound => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Not found',
    },
    Kanopya::Exception::Internal::IncorrectParam => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Wrong attribute or parameter',
    },
    Kanopya::Exception::Internal::MissingParam => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Parameter <[% param_name %]> missing when calling sub <[% sub_name %]>',
        fields      => [ 'sub_name', 'param_name' ],
    },
    Kanopya::Exception::Internal::UnknownCategory => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Unknown category type',
        fields      => [ 'sub_name', 'param_name' ],
    },
    Kanopya::Exception::Internal::UnknownClass => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Unknown class',
    },
    Kanopya::Exception::Internal::UnknownAttribute => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Unknown attribute',
    },
    Kanopya::Exception::Internal::AbstractClass => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Can\'t instantiate abstract class',
    },
    Kanopya::Exception::Internal::UnknownResource => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Unknown resource',
    },
    Kanopya::Exception::Internal::UnknownOperator => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Unknown operator',
    },
    Kanopya::Exception::Internal::Inconsistency => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'Not consistent',
    },
    Kanopya::Exception::Internal::Deprecated => {
        isa         => 'Kanopya::Exception',
        description => 'Deprecated',
    },
    Kanopya::Exception::Internal::NoValue => {
        isa         => 'Kanopya::Exception::Internal',
        description => 'No value for requested data',
    },
    Kanopya::Exception::Execution => {
        isa         => 'Kanopya::Exception',
        description => 'Command execution failed',
    },
    Kanopya::Exception::Execution::API => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'External API call failed',
    },
    Kanopya::Exception::Execution::Command => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'External command execution failed',
        fields      => [ 'command', 'return_code' ],
    },
    Kanopya::Exception::Execution::Rollbacked => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Operation execution rollbacked',
    },
    Kanopya::Exception::Execution::OperationReported => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Operation execution reported',
    },
    Kanopya::Exception::Execution::OperationInterrupted => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Operation execution interrupted',
    },
    Kanopya::Exception::Execution::OperationRequireValidation => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Operation execution require validation',
    },
    Kanopya::Exception::Execution::InvalidState => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Invalid context object state',
    },
    Kanopya::Exception::Execution::Locked => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Entity already locked',
    },
    Kanopya::Exception::Execution::ResourceBusy => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Resource busy',
    },
    Kanopya::Exception::Execution::AlreadyExists => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Already exist',
    },
    Kanopya::Exception::AuthenticationRequired => {
        isa         => 'Kanopya::Exception',
        description => 'Authentication required',
    },
    Kanopya::Exception::AuthenticationFailed => {
        isa         => 'Kanopya::Exception',
        description => 'Incorrect Login/Password values pair',
    },
    Kanopya::Exception::Permission => {
        isa         => 'Kanopya::Exception',
        description => 'Kanopya Permission Exception'
    },
    Kanopya::Exception::Permission::Denied => {
        isa         => 'Kanopya::Exception::Permission',
        description => 'Permission denied'
    },
    Kanopya::Exception::NotImplemented => {
        isa         => 'Kanopya::Exception',
        description => 'Method not implemented'
    },
    Kanopya::Exception::InvalidConfiguration => {
        isa         => 'Kanopya::Exception',
        description => 'Invalid configuration',
        fields      => [ 'component' ]
    },
    Kanopya::Exception::Daemon => {
        isa         => 'Kanopya::Exception',
        description => 'Kanopya Daemon Exception'
    },
    Kanopya::Exception::MessageQueuing => {
        isa         => 'Kanopya::Exception',
        description => 'Kanopya MessageQueuing Exception'
    },
    Kanopya::Exception::MessageQueuing::ConnectionFailed => {
        isa         => 'Kanopya::Exception::MessageQueuing',
        description => 'Connection failed'
    },
    Kanopya::Exception::MessageQueuing::ChannelError => {
        isa         => 'Kanopya::Exception::MessageQueuing',
        description => 'Channel error',
    },
    Kanopya::Exception::MessageQueuing::NoMessage => {
        isa         => 'Kanopya::Exception::MessageQueuing',
        description => 'No message to fetch'
    },
    Kanopya::Exception::MessageQueuing::PublishFailed => {
        isa         => 'Kanopya::Exception::MessageQueuing',
        description => 'Unable to publish on channel',
        fields      => [ 'queue', 'body' ],
    },
);

# Force print trace when exception is stringified
# For Kanopya::Exception and all its subclasses
Kanopya::Exception->Trace(1);


=pod
=begin classdoc

Override method called when exception is stringified.
Add Exception type in message

=end classdoc
=cut

sub Kanopya::Exception::full_message {
    my $self = shift;
    return (ref $self) . ' => ' . $self->user_message . "\n";
}


=pod
=begin classdoc

Define a user friendly message for exception.
Process template description replacing fields by their values
Warning a field 'error' in Exception replaces the templated message.

=end classdoc
=cut

sub Kanopya::Exception::user_message {
    my $self = shift;

    # Print the specific error message if defined
    # $self->message corresponds to the field 'error' in the exception declaration

    if (defined $self->message && $self->message ne "") {
        return $self->message;
    }

    # Print the (maybe templated) description
    my $template = Template->new();
    my $message_template = $self->description;

    my $fields = {};
    map {$fields->{$_} = $self->$_} $self->Fields;

    my $message = '';
    $template->process(\$message_template, $fields, \$message)
        or throw Kanopya::Exception::Internal(
                     error => "Error when processing template : " . $template->error()
                 );
    return $message;
}

1;
