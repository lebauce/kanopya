# EMotherboard.pm - Abstract class of EMotherboards object

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

EMotherboard - execution class of motherboard entities

=head1 SYNOPSIS



=head1 DESCRIPTION

EMotherboard is the execution class of motherboard entities

=head1 METHODS

=cut
package EEntity::EMotherboard;
use base "EEntity";

use strict;
use warnings;
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

=head2 new

    my comp = EMotherboard->new();

EMotherboard::new creates a new component object.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
	$self->_init();
    
    return $self;
}

=head2 _init

EMotherboard::_init is a private method used to define internal parameters.

=cut

sub _init {
	my $self = shift;

	return;
}



1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut