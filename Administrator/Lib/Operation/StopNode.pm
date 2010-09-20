# StopNode.pm - Operation class implementing Cluster stop operation

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

Operation::StopNode - Operation class implementing node stop operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement node stop operation

=head1 DESCRIPTION

=head1 METHODS

=cut
package Operation::StopNode;

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

    my $op = Operation::StopNode->new();

Operation::StopNode->new creates a new StopNode operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
	
	# presence of 'params' named argument is done in parent class 
    my $self = $class->SUPER::new( %args );
    my $admin = $args{administrator};
     
	# check if node exist in db
    $log->debug("checking node existence");
    my $node = $admin->{db}->resultset('Node')->search( { 
    	motherboard_id => $args{params}->{motherboard_id},
    	cluster_id => $args{params}->{cluster_id}
    })->single;
    if(not defined $node) {
    	my $errmsg = "Operation::StopNode->new : can't find this node in db (cluster_id is $args{params}->{cluster_id}, motherboard_id is $args{params}->{motherboard_id})";
    	$log->error($errmsg);
    	throw Mcs::Exception::Internal(error => $errmsg);
    }
        
    # check if node is up
    #TODO comment fait-on pour les nodes broken ?
    #logiquement on pourra éteindre un node broken quand on manipulera la carte de dispatch
    my $motherboard = $admin->getEntity(type => 'Motherboard', id => $args{params}->{motherboard_id} ); 
    
    if($motherboard->getAttr(name => 'motherboard_state') ne 'up') {
    	my $errmsg = "Operation::StopNode->new : motherboard must be up to be stopped";
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