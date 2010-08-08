# EFactory.pm - Module which instanciate EEntity and EContext

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

EFactory - Module which instanciate EEntity and EContext

=head1 SYNOPSIS

    use EFactory;
    
    # Creates an EEntity
    my $eentity = EFactory::newEEntity();
    
    # Create an EContext
    my $econtext = EFactory::newEContext

=head1 DESCRIPTION


=head1 METHODS

=cut
package EFactory;

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

EFactory::newEEntity($objdata) instanciates a new object EEntity from Entity.

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

=head2 newEContext

EFactory::newEContext(ip_source, ip_destination) instanciates a new object EContext.

=cut

sub newEContext {
	shift;
	my %args = @_;
	if ((! exists $args{ip_source} or ! defined $args{ip_source}) ||
		(! exists $args{ip_destination} or ! defined $args{ip_destination}))
	{ 
		throw Mcs::Exception::Internal::IncorrectParam(error => "EFactory::newEContext need ip_source and ip_destination named argument! ($args{ip_destination} - $args{ip_source})"); }
	
	#TODO Check if ips is good format
	#Create EContext::Local or EContext::SSH
	if($args{ip_source} eq $args{ip_destination}) {
		# EContext::Local
		$log->debug("ip_source & ip_destination are the same, using EContext::Local");
		use EContext::Local;
		return EContext::Local->new();
	} else {
		# EContext::SSH
		use EContext::SSH;
		my $ssh = EContext::SSH->new(ip => $args{ip_destination});
		return $ssh;
	}
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
