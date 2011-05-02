# AddComponentToCluster.pm - Operation class implementing Component in cluster addition operation

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

Operation::AddComponentToCluster - Operation class implementing Component in cluster addition operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Component in cluster addition operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package Operation::AddComponentToCluster;
use base "Operation";

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);

use Data::Dumper;


my $log = get_logger("administrator");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = Operation::AddComponentToCluster->new();

Operation::AddComponentToCluster->new creates a new AddComponentToCluster operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;

	# presence of 'params' named argument is done in parent class
    my $self = $class->SUPER::new( %args );
    my $admin = $args{administrator};
        
    # check params content
    $log->debug("checking needed parameters");
    if((! exists $args{params}->{cluster_id} or !defined $args{params}->{cluster_id}) ||
       (! exists $args{params}->{component_id} or !defined $args{params}->{component_id}) ||
       (! exists $args{params}->{component_template_id} or !defined $args{params}->{component_template_id})) {
    	$errmsg = "Operation::AddComponentToCluster->new : params need cluster_id, component_id and component_template_id";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);	
    }
    
    # check if cluster_id exist
    $log->debug("checking cluster existence with id <$args{params}->{cluster_id}>");
    my $row = $admin->{db}->resultset('Cluster')->find($args{params}->{cluster_id});
    if(! defined $row) {
    	$errmsg = "Operation::AddComponentToCluster->new : cluster_id $args{params}->{cluster_id} does not exist";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # check if component_id exist
    $log->debug("checking component existence with id <$args{params}->{component_id}>");
    $row = $admin->{db}->resultset('Component')->find($args{params}->{component_id});
    if(! defined $row) {
    	$errmsg = "Operation::AddComponentToCluster->new : component_id $args{params}->{component_id} does not exist";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # check if component_template_id exist
    $log->debug("checking component template existence with id <$args{params}->{component_template_id}>");
    $row = $admin->{db}->resultset('ComponentTemplate')->find($args{params}->{component_template_id});
    if(! defined $row) {
    	$errmsg = "Operation::AddComponentToCluster->new : component_template_id $args{params}->{component_template_id} does not exist";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
	# check if component not already added to the cluster
	$log->debug("checking unexistence of the component on this cluster");
    $row = $admin->{db}->resultset('ComponentInstance')->search(
    	{ cluster_id => $args{params}->{cluster_id},
    	  component_id => $args{params}->{component_id} }
    )->single;
    if(defined $row) {
    	$errmsg = "Operation::AddComponentToCluster->new : cluster with id $args{params}->{cluster_id} already has component with id $args{params}->{component_id}";
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