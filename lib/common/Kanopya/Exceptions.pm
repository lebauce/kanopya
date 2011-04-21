package Kanopya::Exceptions;
use Data::Dumper;
=head1 NAME

<KanopyaExceptions> – <General class containing Kanopya exceptions>

=head1 VERSION

This documentation refers to <KanopyaExceptions> version 1.0.0.

=head1 SYNOPSIS

use <KanopyaExceptions>;

throw Kanopya::Exception(error => $errmsg);

throw Kanopya::Exception::DB(error => $errmsg);

throw Kanopya::Exception::Network(error => $errmsg);

throw Kanopya::Exception::Internal(error => $errmsg);

throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);

throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);

throw Kanopya::Exception::Execution(error => $errmsg);

throw Kanopya::Exception::Execution::OperationReported(error => $errmsg);

throw Kanopya::Exception::AuthentificationRequired(error => $errmsg);

throw Kanopya::Exception::LoginFailed(error => $errmsg);

throw Kanopya::Exception::Permission(error => $errmsg);

throw Kanopya::Exception::Permission::Denied(error => $errmsg);

=head1 DESCRIPTION

This is Kanopya Exceptions package documentation.
Kanopya has it own exception to manage internal error and show to user comprehensive error message.

=cut




use Exception::Class (
    Kanopya::Exception => {
	description => "Kanopya General Exception",
	fields => [ 'level', 'request' ],
    },
    Kanopya::Exception::DB => {
	isa => 'Kanopya::Exception',
	description => 'Kanopya Database exception',
    },
    Kanopya::Exception::Network => {
	isa => 'Kanopya::Exception',
	description => 'MicroCluster SSH communication exception',
    },
    Kanopya::Exception::Internal => {
	isa => 'Kanopya::Exception',
	description => 'Kanopya Internal exception',
    },
    Kanopya::Exception::Internal::WrongValue => {
	isa => 'Kanopya::Exception::Internal',
	description => 'Wrong Value',
    },
    Kanopya::Exception::Internal::IncorrectParam => {
	isa => 'Kanopya::Exception::Internal',
	description => 'Wrong attribute or parameter',
    },
    Kanopya::Exception::Execution => {
	isa => 'Kanopya::Exception',
	description => 'Command execution failed',
    },
    Kanopya::Exception::Execution::OperationReported => {
	isa => 'Kanopya::Exception::Execution',
	description => 'Operation execution reported',
	},
	Kanopya::Exception::AuthenticationRequired => {
	isa => 'Kanopya::Exception',
	description => 'Authentication required',
	},
	Kanopya::Exception::AuthenticationFailed => {
	isa => 'Kanopya::Exception',
	description => 'Incorrect Login/Password values pair',
	},
	Kanopya::Exception::Permission => {
	isa => 'Kanopya::Exception',
	description => 'Kanopya Permission Exception'
	},
	Kanopya::Exception::Permission::Denied => {
	isa => 'Kanopya::Exception::Permission',
	description => 'Permission denied'
	},
	Kanopya::Exception::OperationAlreadyEnqueued => {
	isa => 'Kanopya::Exception',
	description => 'Operation already enqueued' 	
	},
    
    
);

# Force print trace when exception is stringified
# For Kanopya::Exception and all its subclasses
Kanopya::Exception->Trace(1);

# Override method called when exception is stringified
sub Kanopya::Exception::full_message {
 	my $self = shift;
	
	my $except_string = "## EXCEPTION : " . $self->description . " ##\n";
	$except_string .= $self->message;

	# TODO add fileds and value in string
	#( Dumper $self->Fields );	
	#for my $field (@{ $self->fields }) {
	#	$except_string .= $field;
	#}

 	return $except_string;

}


=head1 DIAGNOSTICS

No exception

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item Exception::Class module perl implementing exceptions

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
