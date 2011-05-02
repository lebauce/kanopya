# UpdateClusterNodeStarted.pm - Operation class implementing Cluster start operation

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
# Created 26 Octobre 2010

=head1 NAME

Operation::UpdateClusterNodeStarted - Operation class implementing Cluster start operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Cluster start operation

=head1 DESCRIPTION

=head1 METHODS

=cut
package Operation::UpdateClusterNodeStarted;

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

    my $op = Operation::UpdateClusterNodeStarted->new();

Operation::UpdateClusterNodeStarted->new creates a new UpdateClusterNodeStarted operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
	
	# presence of 'params' named argument is done in parent class 
    my $self = $class->SUPER::new( %args );
    my $admin = $args{administrator};
    
    if ((! exists $args{params}->{cluster_id} or ! defined $args{params}->{cluster_id}) ||
		(! exists $args{params}->{motherboard_id} or ! defined $args{params}->{motherboard_id})) { 
		$errmsg = "Operation::UpdateClusterNodeStarted->new : params Need a motherboard_id and a cluster_id";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
    
	# check if cluster exists in db
    $log->debug("checking cluster existence with id <$args{params}->{cluster_id}>");
    my $cluster = $admin->getEntity(type => 'Cluster', id => $args{params}->{cluster_id});
    
    # check if cluster is active and down
    if($cluster->getAttr(name => 'active') == 0 or $cluster->getAttr(name => 'cluster_state') ne 'up') {
    	my $errmsg = "Operation::UpdateClusterNodeStarted->new : cluster must be active and started to be Updated";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    # check if motherboard exists in db
    $log->debug("checking motherboard existence with id <$args{params}->{motherboard_id}>");
    my $motherboard = $admin->getEntity(type => 'Motherboard', id => $args{params}->{motherboard_id});

    # check if motherboard is active, up
    if($motherboard->getAttr(name => 'active') == 0 ) {
    	my $errmsg = "Operation::UpdateClusterNodeStarted->new : motherboard must be active and started";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
	
	# Check if motherboard is in cluster
	if (!$admin->{db}->resultset('Node')->search({
      motherboard_id => $args{params}->{motherboard_id},
      cluster_id  => $args{params}->{cluster_id}})){
    	my $errmsg = "Operation::UpdateClusterNodeStarted->new : motherboard $args{params}->{motherboard_id} is not in cluster $args{params}->{cluster_id}";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
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
1;
__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut