# ModifyCluster.pm - Operation class implementing Cluster modification operation

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

Operation::ModifyCluster - Operation class implementing Cluster modification operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Cluster modification operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package Operation::ModifyCluster;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use base "Operation";
use Entity::Cluster;

my $log = get_logger("administrator");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = Operation::ModifyCluster->new();

Operation::AddMotherboard->new creates a new ModifyCluster operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
	
	# presence of 'params' named argument is done in parent class 
    my $self = $class->SUPER::new( %args );
    my $admin = $args{administrator};
    my $row;

	#TODO check ModifyCluster
	# Checker cluster exists
	# Checker que les parametres passé sont bien modifiable (param is_editable)
	# checker si les valeur est reellement modifiée
	# Checker chacun des parametre avec checkAttr
     
 	# check validity of cluster attributes
    #Entity::Cluster->checkAttrs(attrs => $args{params});   
    # if kernel_id present, check if exists
    if(exists $args{params}->{kernel_id}) {
    	$log->debug("checking kernel existence with id <$args{params}->{kernel_id}>");
    	if ($args{params}->{kernel_id} == 0){
    		$args{params}->{kernel_id} = undef;
    	}else {
		    $row = $admin->{db}->resultset('Kernel')->find($args{params}->{kernel_id});
		    if(! defined $row) {
		    	$errmsg = "Operation::ModifyCluster->new : kernel_id $args{params}->{kernel_id} does not exist";
		    	$log->error($errmsg);
		    	throw Kanopya::Exception::Internal(error => $errmsg);
	    	}
    	}
    }
    
    # check validity of min_node and max_node
    $log->debug("checking validity of cluster_min_node <$args{params}->{cluster_min_node}>");
    $log->debug("checking validity of cluster_max_node <$args{params}->{cluster_max_node}>");
    my $totalmotherboards = $admin->countEntities(type => 'Motherboard');
    if(($args{params}->{cluster_min_node} > $totalmotherboards) ||
       ($args{params}->{cluster_max_node} > $totalmotherboards)) {
       	$errmsg = qq/Operation::ModifyCluster->new : 
       	cluster_min_node ($args{params}->{cluster_min_node}) and 
       	cluster_max_node ($args{params}->{cluster_max_node}) can't 
       	exceed total motherboards number ($totalmotherboards)/;
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    if(! $args{params}->{cluster_min_node} > $args{params}->{cluster_max_node}) {
    	$errmsg = qq/Operation::ModifyCluster->new : 
       	cluster_min_node ($args{params}->{cluster_min_node}) must  
       	be inferior or equal cluster_max_node ($args{params}->{cluster_max_node})/;
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

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut