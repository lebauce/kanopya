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
package EEntityFactory;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);
use lib qw(../../Administrator/Lib ../../Common/Lib);
use General;
use McsExceptions;

my $log = get_logger("executor");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 newEEntity

EEntityFactory::newEEntity($objdata) instanciates a new object EEntity from Entity.

=cut

sub newEEntity {
#	my $self = shift;
	my %args = @_;
	
	if (! exists $args{data} or ! defined $args{data}) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "EntityFactory->newEEntity need a data named argument!"); }
	my $data = $args{data};
	my $class = General::getClassEEntityFromEntity(entity => $data);
	$log->debug("GetClassEEntityFromEntity return $class"); 
	my $location = General::getLocFromClass(entityclass => $class);
	$log->debug("General::getLocFromClass return $location"); 
	
    require $location;

    return $class->new(data => $args{data});
}
1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
