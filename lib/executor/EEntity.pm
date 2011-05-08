# EEntity.pm - Entity is the highest general execution object

#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

EEntity - EEntity is the highest general execution object

=head1 SYNOPSIS



=head1 DESCRIPTION

EEntity is the highest general execution object

=head1 METHODS

=cut
package EEntity;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use vars qw(@ISA $VERSION);

my $log = get_logger("executor");
my $errmsg;

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $mb = Entity->new();

Entity>new($data : hash EntityData) creates a new entity execution object.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    if ((! exists $args{data} or ! defined $args{data})) { 
		$errmsg = "EEntity->new ($class) need a data named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
    }
        
#   	$log->debug("Class is : $class");
    my $self = { _entity => $args{data}};
    bless $self, $class;
    return $self;
}

sub _getEntity{
	my $self = shift;
	return $self->{_entity};
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut