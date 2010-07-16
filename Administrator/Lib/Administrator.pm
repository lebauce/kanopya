# Administrator.pm - Object class of Administrator server

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

Administrator - Administrator object

=head1 SYNOPSIS

    use Executor;
    
    # Creates executor
    my $adm = Administrator->new();
    
    # Get object
    $adm->getobject($type : String, %ObjectDefinition);


=head1 DESCRIPTION

Administrator is the main object use to create administrator objects

=head1 METHODS

=cut

package Administrator;


use strict;
use AdministratorDB::Schema;
use Data::Dumper;

###########################################
# new (login, password)
# 
# object constructor


sub new {
	my $class = shift;
	my %args = @_;
	
	my $login = $args{login};
	my $password = $args{password};
	 
	# ici on va chercher la conf pour se connecter à la base 
	my $dbi = 'dbi:mysql:administrator:10.0.0.1:3306';
	my $user = 'root';
	my $pass = 'Hedera@123';
	my %opts = ();
		
	my $self = {
		db => AdministratorDB::Schema->connect($dbi, $user, $pass, \%opts),
	};
	
	if( ! $self->{db} ) { die "Unable to connect to the database : "; }
	
	# on recup l'identite de l'utilisateur
	$self->{user} = $self->{db}->resultset('User')->find( { user_login => $login } );
	
	if(! $self->{user} || $self->{user}->user_password ne $password) {
		warn "incorrect login/password pair";
		return undef;
	}
	
	bless $self, $class;
	return $self;
}

# private


# permet de faire le lien entre les classes qui n'ont pas le meme noms que la table en bd
# pas beau trouver autre chose
sub _mapName {
	my %ClassTableMapping = (
		"Operation" => "OperationQueue" );
	
	my ($class_name) = @_;
	my $table_name = $ClassTableMapping{ $class_name };
	return $table_name ? $table_name : $class_name; 	
}

# get dbix class
sub _getData {
	my $self = shift;
	my ( $class_name, $id ) = @_;

	return $self->{db}->resultset( _mapName( $class_name ) )->find( $id );
}

# create dbix class and add row in db
sub _addData {
	my $self = shift;
	my ( $class_name, $obj_params )  = @_;	
	$obj_params = {} if !$obj_params;
	
	my $new_obj = $self->{db}->resultset( _mapName( $class_name ) )->create( $obj_params );
	return $new_obj;	
}

# create dbix class
sub _newData {
	my $self = shift;
	my ( $class_name, $obj_params )  = @_;	
	$obj_params = {} if !$obj_params;	
	
	my $new_obj = $self->{db}->resultset( _mapName( $class_name ) )->new( $obj_params );
	
	return $new_obj;
}

sub getObj {

}

sub getObjs {}

sub getAllObjs {}

sub newObj {}

sub saveObj {}

=head2 getNextOperation

	adm->getNextOperation() : Operationdata send the next operation.

=cut

sub getNextOperation {
	
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut