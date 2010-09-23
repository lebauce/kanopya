# CreateSharedDisk.pm - Operation class implementing Shared Disk addition operation 

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

Operation::AddSystemimage - Operation class implementing  System image cloning operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image cloning operation

=head1 DESCRIPTION

=head1 METHODS

=cut
package Operation::CreateSharedDisk;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use base "Operation";
use Entity::Systemimage;
my $log = get_logger("administrator");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = Operation::CreateSharedDisk->new();

Operation::CreateSharedDisk->new creates a new CreateSharedDisk operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;

	# presence of 'params' named argument is done in parent class
	my $self = $class->SUPER::new( %args );
	my $admin = $args{administrator};
	
	if (! exists $args{params}->{disk_name} or ! defined $args{params}->{disk_name}) {
    	$errmsg = "Operation::CreateSharedDisk->new : params need a disk_name parameter!";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    if (! exists $args{params}->{disk_size} or ! defined $args{params}->{disk_size}) {
    	$errmsg = "Operation::CreateSharedDisk->new : params need a disk_size parameter!";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    if (! exists $args{params}->{disk_fs} or ! defined $args{params}->{disk_fs}) {
    	$errmsg = "Operation::CreateSharedDisk->new : params need a disk_fs parameter!";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    if (! exists $args{params}->{export_client_instance_id} or ! defined $args{params}->{export_client_instance_id}) {
    	$errmsg = "Operation::CreateSharedDisk->new : params need a export_client_instance_id parameter!";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    if (! exists $args{params}->{export_instance_id} or ! defined $args{params}->{export_instance_id}) {
    	$errmsg = "Operation::CreateSharedDisk->new : params need a export_instance_id parameter!";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    #TODO Get Storage cluster as a parameter
#    if (! exists $args{params}->{storage_cluster_id} or ! defined $args{params}->{storage_cluster_id}) {
#    	$errmsg = "Operation::CreateSharedDisk need a storage_cluster_id parameter!";
#    	$log->error($errmsg);
#    	throw Mcs::Exception::Internal(error => $errmsg);
#    }
	
	if (! exists $args{params}->{mount_point} or ! defined $args{params}->{mount_point}) {
    	$errmsg = "Operation::CreateSharedDisk need a mount_point parameter!";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
	
	if (! exists $args{params}->{mount_options} or ! defined $args{params}->{mount_options}) {
    	$errmsg = "Operation::CreateSharedDisk need a mount_options parameter!";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
	
	if (! exists $args{params}->{cluster_id} or ! defined $args{params}->{cluster_id}) {
    	$errmsg = "Operation::CreateSharedDisk need a cluster_id parameter!";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
	
	#TODO Need cluster if we hotly update shared disk on cluster
	
	# check if vg has enough free space
#    my $sysimg = $admin->getEntity(type => 'Systemimage', id => $args{params}->{systemimage_id});
#    my $devices = $sysimg->getDevices;
#    my $neededsize = $devices->{etc}->{lvsize} + $devices->{root}->{lvsize};
#    $log->debug("Size needed for systemimage devices : $neededsize M"); 
#    $log->debug("Freespace left : $devices->{etc}->{vgfreespace} M");
#    if($neededsize > $devices->{etc}->{vgfreespace}) {
#    	$errmsg = "Operation::CreateSharedDisk->new : not enough freespace on vg $devices->{etc}->{vgname} ($devices->{etc}->{vgfreespace} M left)";
#    	$log->error($errmsg);
#    	throw Mcs::Exception::Internal(error => $errmsg);
#    }
	
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