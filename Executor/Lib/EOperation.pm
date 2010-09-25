# EOperation.pm - 

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

EOperation - Abstract class of EOperation object

=head1 SYNOPSIS



=head1 DESCRIPTION

Component is an abstract class of EOperation objects

=head1 METHODS

=cut
package EOperation;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib "..";

my $log = get_logger("executor");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub _getOperation{
	my $self = shift;
	return $self->{_operation};
}

=head2 new

    my comp = EOperation->new();

	EOperation->new creates a new operation object.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    if ((! exists $args{data} or ! defined $args{data})) { 
		$errmsg = "EOperation->new ($class) need a data named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
   	}
    
    
   	$log->debug("Class is : $class");
    my $self = { _operation => $args{data}};
    bless $self, $class;
	$self->_init();

    return $self;
}

=head2 _init

Eoperation::_init is a private method used to define internal parameters.

=cut

sub _init {
	my $self = shift;
	$self->{internal_cluster} = {};
	return;
}

=head2 prepare

	$op->prepare();

=cut

sub prepare {
	my $self = shift;
	
	my $id = $self->_getOperation();
	$log->debug("Class is : $id");
	$self->{userid} = $self->_getOperation()->getAttr(attr_name => "user_id");
	$log->debug("Change user by user_id : $self->{userid}");	
	my $adm = Administrator->new();
	#$adm->changeUser(user_id => $self->{userid});
	$log->debug("Change user effective : New user is $adm->{_rightschecker}->{_user}");
}

sub execute {}

sub finish {}

sub delete {
	my $self = shift;
	my $adm = Administrator->new();
	$self->{_operation}->delete();	
}
1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut