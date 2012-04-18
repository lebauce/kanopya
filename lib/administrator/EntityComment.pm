# EntityComment.pm  

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Hedera Technology sas.

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
# Created 16 july 2010

=head1 NAME

EntityComment

=head1 SYNOPSIS


=head1 DESCRIPTION

    Base class for EntityComment

=cut

package EntityComment;

use base "BaseDB";

use strict;
use warnings;
use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;
use General;
our $VERSION = "1.00";

my $log = get_logger("administrator");
my $errmsg;

=head2 _getEntityIds

    Class : Protected
    
    Desc : return an array reference containing entity id and its groups entity ids
    
    args :
            entity_id : entity_id about an entity object
    return : array reference of entity_id 

=cut

sub _getEntityIds {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['entity_id']);

    my $ids = [];
    # TODO verifier que l'entity_id fournit exists en base
    push @$ids, $args{entity_id};
    
    # retrieve entity_id of groups containing this entity object
    my @groups = $self->{schema}->resultset('Gp')->search( 
        { 'ingroups.entity_id' => $args{entity_id} },
        { join                 => [qw/ingroups gp_entity/] }
    );
    # add entity_id groups to the arrayref
    foreach my $g (@groups) { 
        push @$ids, $g->id;
    }
    
    return $ids;
}

=head2 getEntityComment

=cut

sub getEntityComment {
    my $class = shift;
    my %args = @_;
    General::checkParams(args => \%args, required => ['hash']);

return $class->search(%args);
}


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut