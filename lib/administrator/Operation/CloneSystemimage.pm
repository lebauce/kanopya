# CloneSystemimage.pm - Operation class implementing System image cloning operation 

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Hedera Technology sas.

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

Operation::AddSystemimage - Operation class implementing  System image cloning operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image cloning operation

=head1 DESCRIPTION

=head1 METHODS

=cut
package Operation::CloneSystemimage;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use base "Operation";
use Entity::Systemimage;
my $log = get_logger("administrator");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = Operation::CloneSystemimage->new();

Operation::CloneSystemimage->new creates a new CloneSystemimage operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;

	# presence of 'params' named argument is done in parent class
	my $self = $class->SUPER::new( %args );
	my $admin = $args{administrator};
	
	if (! exists $args{params}->{systemimage_name} or ! defined $args{params}->{systemimage_name}) {
    	$errmsg = "Operation::CloneSystemimage->new : params need a systemimage_name parameter!";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
    if (! exists $args{params}->{systemimage_id} or ! defined $args{params}->{systemimage_id}) {
    	$errmsg = "Operation::CloneSystemimage need a distribution_id parameter!";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
	
	# check if systemimage source exists
	my $row = $admin->{db}->resultset('Systemimage')->find($args{params}->{systemimage_id});
    if(! defined $row) {
    	$errmsg = "Operation::CloneSystemimage->new : systemimage_id $args{params}->{systemimage_id} does not exist";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }	
	
	 # check if systemimage name does not already exist
    $row = $admin->{db}->resultset('Systemimage')->find({systemimage_name => $args{params}->{systemimage_name}});
    if(defined $row) {
    	$errmsg = "Operation::CloneSystemimage->new : systemimage_name $args{params}->{systemimage_name} already exists";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
	
	# check validity of systemimage attributes     
    Entity::Systemimage->checkAttr(name => 'systemimage_name', value => $args{params}->{systemimage_name});
    if(exists $args{params}->{systemimage_desc}) {
    	Entity::Systemimage->checkAttr(name => 'systemimage_desc', value => $args{params}->{systemimage_desc});
    }
	
	# check if vg has enough free space
    my $sysimg = $admin->getEntity(type => 'Systemimage', id => $args{params}->{systemimage_id});
    my $devices = $sysimg->getDevices;
    my $neededsize = $devices->{etc}->{lvsize} + $devices->{root}->{lvsize};
    $log->debug("Size needed for systemimage devices : $neededsize M"); 
    $log->debug("Freespace left : $devices->{etc}->{vgfreespace} M");
    if($neededsize > $devices->{etc}->{vgfreespace}) {
    	$errmsg = "Operation::CloneSystemimage->new : not enough freespace on vg $devices->{etc}->{vgname} ($devices->{etc}->{vgfreespace} M left)";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
	
    return $self;
}

=head2 _init

	$op->_init() is a private method used to define internal parameters.

=cut

sub _init {
	my $self = shift;
	return;
}

=head2 prepare

	$op->prepare();

=cut

sub prepare {
	my $self = shift;
	my $adm = Administrator->new();
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut