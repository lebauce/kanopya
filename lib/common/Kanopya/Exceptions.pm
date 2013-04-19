#    Copyright © 2011 Hedera Technology SAS
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

@since    2011-Jan-13

=end classdoc

=cut

package Kanopya::Exceptions;

use Exception::Class (
    Kanopya::Exception => {
        description => "Kanopya General Exception",
        fields      => [ 'level', 'request', 'hidden' ],
    },
    Kanopya::Exception::DB => {
        isa         => 'Kanopya::Exception',
        description => 'Kanopya Database exception',
    },
    Kanopya::Exception::DB::Cascade => {
        isa         => 'Kanopya::Exception::DB',
        description => 'Kanopya Database cascade exception',
    },
    Kanopya::Exception::Network => {
        isa         => 'Kanopya::Exception',
        description => 'SSH communication exception',
    },
    Kanopya::Exception::Quota => {
        isa         => 'Kanopya::Exception',
        description => 'Quota exceeded',
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
        description => 'Parameter missing or undefined',
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
    Kanopya::Exception::Execution => {
        isa         => 'Kanopya::Exception',
        description => 'Command execution failed',
    },
    Kanopya::Exception::Execution::Rollbacked => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Operation execution rollbacked',
    },
    Kanopya::Exception::Execution::OperationReported => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Operation execution reported',
    },
    Kanopya::Exception::Execution::Locked => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Entity already locked',
    },
    Kanopya::Exception::Execution::ResourceBusy => {
        isa         => 'Kanopya::Exception::Execution',
        description => 'Resource busy',
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
    Kanopya::Exception::OperationAlreadyEnqueued => {
        isa         => 'Kanopya::Exception',
        description => 'Operation already enqueued'
    },
    Kanopya::Exception::NotImplemented => {
        isa         => 'Kanopya::Exception',
        description => 'Method not implemented'
    },
    Kanopya::Exception::MessageQueuing => {
        isa         => 'Kanopya::Exception',
        description => 'Kanopya MessageQueuing Exception'
    },
    Kanopya::Exception::MessageQueuing::NoMessage => {
        isa         => 'Kanopya::Exception::MessageQueuing',
        description => 'No message to fetch'
    },
);

# Force print trace when exception is stringified
# For Kanopya::Exception and all its subclasses
Kanopya::Exception->Trace(0);

# Override method called when exception is stringified
sub Kanopya::Exception::full_message {
    my $self = shift;
    my $except_string = $self->description . ": ";
    $except_string .= $self->message if ($self->message ne "");

    # Show fields
    for my $field ( $self->Fields ) {
        $except_string .= ("\n=> " . $field . ": '" . $self->$field . "'") if (defined $self->$field);
    }

     return $except_string;
}

1;
