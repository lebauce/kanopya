# StartCluster.pm - Operation class implementing Cluster start operation

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

Operation::StartCluster - Operation class implementing Cluster start operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Cluster start operation

=head1 DESCRIPTION

=head1 METHODS

=cut
package Operation::StartCluster;
use base "Operation";

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Entity::Cluster;
use Entity::Systemimage;
use Entity::Motherboard;

my $log = get_logger("administrator");
my $errmsg;

our $VERSION = "1.00";

=head2 new

    my $op = Operation::StartCluster->new();

Operation::StartCluster->new creates a new StartCluster operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
	
	# presence of 'params' named argument is done in parent class 
    my $self = $class->SUPER::new( %args );
    my $admin = $args{administrator};
     
	# check if cluster exist in db
    $log->debug("checking cluster existence with id <$args{params}->{cluster_id}>");
    my $cluster = Entity::Cluster->get(id => $args{params}->{cluster_id});
    
    # check if cluster is active and down
    if($cluster->getAttr(name => 'active') == 0 or $cluster->getAttr(name => 'cluster_state') ne 'down') {
    	my $errmsg = "Operation::StartCluster->new : cluster must be active and down to be started";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    # check if systemimage is active
    my $systemimage = Entity::Systemimage->get(id => $cluster->getAttr(name => 'systemimage_id'));
    if($systemimage->getAttr(name => 'active') == 0) {
    	my $errmsg = "Operation::StartCluster->new : cluster's systemimage is not active ; activate it to start the cluster";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
    
    # check if there are enough free motherboard to start cluster min nodes
    my @freemotherboards = $admin->getEntities(
    	type => 'Motherboard', 
    	hash => { active => 1, motherboard_state => 'down'});

	if(scalar(@freemotherboards) < $cluster->getAttr(name => 'cluster_min_node')) {
		my $errmsg = "Operation::StartCluster->new : not enough free motherboards to start this cluster ;";
		$errmsg .= "minimum nodes required is ". $cluster->getAttr(name => 'cluster_min_node');
		$errmsg .= " and only ".scalar(@freemotherboards). " motherboards are available";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
	}    

	return $self;
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