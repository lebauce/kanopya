# EEntityFactory.pm - Module which instanciate EEntity

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

EEntityFactory - Module which instanciate EEntity

=head1 SYNOPSIS

    use EEntityFactory;
    
    # Creates an EEntity
    my $eentity = EEntityFactory::newEEntity();

=head1 DESCRIPTION


=head1 METHODS

=cut
package EContext;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw(../../Administrator/Lib ../../Common/Lib);

use McsExceptions;

my $log = get_logger("executor");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $contexts ={};

=head2 newContext

EEntityFactory::newContext(ip) instanciates a new object Context

=cut
sub newContext {
	my $self = shift;
	my %args = @_;
	
	if (! exists $args{ip} or ! defined $args{ip}) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "EContext->newContext need a ip named argument!"); }
	if (exists $contexts->{$args{ip}} and defined $contexts->{$args{ip}}) {
		return $contexts->{$args{ip}};
	}
	#TODO Check if ip is good format
	#TODO Test if ip is local or remote
	#TODO Create Context::Local or Context::
}

