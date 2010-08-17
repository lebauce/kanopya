# AddSystemimage.pm - Operation class implementing System image creation operation

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

Operation::AddSystemimage - Operation class implementing  System image creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image creation operation

=head1 DESCRIPTION

=head1 METHODS

=cut
package Operation::AddSystemimage;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use base "Operation";
use Entity::Systemimage;
my $log = get_logger("administrator");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = Operation::AddSystemimage->new();

Operation::AddSystemimage->new creates a new CreateSystemimage operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;

	if (! exists $args{params} or ! defined $args{params}){
		throw Mcs::Exception::Internal(error => "Operation::AddSystemimage->new need params to be checked!"); }
    # Operation parameters checking
    my $p = $args{params};
    if (! exists $p->{systemimage_name} or ! defined $p->{systemimage_name}) {
    	throw Mcs::Exception::Internal(error => "Operation::AddSystemimage need a systemimage_name parameter!"); }
    if (! exists $p->{distribution_id} or ! defined $p->{distribution_id}) {
    	throw Mcs::Exception::Internal(error => "Operation::AddSystemimage need a distribution_id parameter!"); }
    
    	
    
    my $self = $class->SUPER::new( %args );
    
    
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