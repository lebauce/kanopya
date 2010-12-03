# DeactivateCluster.pm - Operation class implementing Cluster deactivation operation

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

Operation::DeactivateCluster - Operation class implementing Cluster deactivation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Cluster deactivation operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package Operation::DeactivateCluster;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use base "Operation";

my $log = get_logger("administrator");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = Operation::DeactivateCluster->new();

Operation::DeactivateCluster->new creates a new DeactivateCluster operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
	
	# presence of 'params' named argument is done in parent class 
    my $self = $class->SUPER::new( %args );
    my $admin = $args{administrator};
     
 	# check if cluster_id exist
    $log->debug("checking cluster existence with id <$args{params}->{cluster_id}>");
    my $row = $admin->{db}->resultset('Cluster')->find($args{params}->{cluster_id});
    if(! defined $row) {
    	$errmsg = "Operation::DeactivateCluster->new : cluster_id $args{params}->{cluster_id} does not exist";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    # check if cluster is active
    $log->debug("checking cluster active value <$args{params}->{cluster_id}>");
   	if(not $row->get_column('active') ) {
	    	$errmsg = "Operation::DeactivateCluster->new : cluster $args{params}->{cluster_id} is not active";
	    	$log->error($errmsg);
	    	throw Mcs::Exception::Internal(error => $errmsg);
    }
      
    # check if cluster is down
    $log->debug("checking cluster state value <$args{params}->{cluster_id}>");
   	  	
   	my $state = $row->get_column('cluster_state'); 
   	if(not ($state eq 'down')) {
	    	$errmsg = "Operation::DeactivateCluster->new : cluster $args{params}->{cluster_id} must be down to be deactivated";
	    	$log->error($errmsg);
	    	throw Mcs::Exception::Internal(error => $errmsg);
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

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut