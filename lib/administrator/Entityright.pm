#    Copyright © 2011-2012 Hedera Technology SAS
#
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

package Entityright;
use base 'BaseDB';

use strict;
use warnings;

use General;
use Kanopya::Exceptions;
use Entity::Gp;

use Log::Log4perl "get_logger";
use Data::Dumper;

our $VERSION = "1.00";

my $log = get_logger("");
my $errmsg;

=head2 _getEntityIds

    Class : Protected
    
    Desc : return an array reference containing entity id and its groups entity ids
    
    args :
            entity_id : entity_id about an entity object
    return : array reference of entity_id 

=cut

sub _getEntityIds {
    my $class = shift;
    my %args = @_;
 
    General::checkParams(args => \%args, required => [ 'entity_id' ]);

    my $ids = [];
    # TODO verifier que l'entity_id fournis exists en base
    push @$ids, $args{entity_id};

    # retrieve entity_id of groups containing this entity object
    my @groups = Entity::Gp->search(hash => { 'ingroups.entity_id' => $args{entity_id} });

    # add entity_id groups to the arrayref
    foreach my $g (@groups) { 
        push @$ids, $g->id;
    }
    
    return $ids;
}

sub match {
    my $class = shift;
    my %args = @_;

    General::checkParams(args     => \%args, 
                         required => [ 'consumer_id', 'consumed_id', 'method' ]);

    my $consumer_ids = $class->_getEntityIds(entity_id => $args{consumer_id});
    my $consumed_ids = $class->_getEntityIds(entity_id => $args{consumed_id});

    return $class->find(hash => {
               entityright_consumer_id => $consumer_ids,
               entityright_consumed_id => $consumed_ids,
               entityright_method      => $args{method}
           });
}

sub addPerm {
    my $class = shift;
    my %args  = @_;
    
    General::checkParams(args => \%args, required => ['consumer_id', 'consumed_id', 'method']);
    
    # TODO: Check if the method exists

    $class->new(entityright_consumer_id => $args{consumer_id},
                entityright_consumed_id => $args{consumed_id},
                entityright_method      => $args{method});
}

sub removePerm {
    my $class = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'consumed_id', 'method' ],
                         optional => { 'consumer_id' => undef });

    my $hash = {
        entityright_method      => $args{method},
        entityright_consumed_id => $args{consumed_id},
    };

    # If no consumer_id defined, remove perms for all users on this method.
    if (defined $args{consumer_id}) {
        $hash->{entityright_consumer_id} = $args{consumer_id};
    }

    my @perms = Entityright->search(hash => $hash);
    for my $perm (@perms) {
        $perm->remove();
    }
}

sub getGrantedMethods {
    my $class = shift;
    my %args  = @_;
    
    General::checkParams(args => \%args, required => ['consumer_id', 'consumed_id']);

    my @rights = $class->search(hash => {
                     entityright_consumer_id => $args{consumer_id},
                     entityright_consumed_id => $args{consumed_id},
                 });

    return map { $_->entityright_method } @rights;
}


1;
