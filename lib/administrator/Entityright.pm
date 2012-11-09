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
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['entity_id']);

    my $ids = [];
    # TODO verifier que l'entity_id fournis exists en base
    push @$ids, $args{entity_id};
    
    # retrieve entity_id of groups containing this entity object
    my @groups = $self->{schema}->resultset('Gp')->search( 
        { 'ingroups.entity_id' => $args{entity_id} },
        { join                 => [qw/ingroups/] }
    );
    # add entity_id groups to the arrayref
    foreach my $g (@groups) { 
        push @$ids, $g->id;
    }
    
    return $ids;
}

=head2 addPerm

    Class : public
    Desc : given a consumer_id - User (or Groups with user type) entity id - a consumed_id 
           and a method, grant the permission to that consumed method for that 
           consumer entity 
    args:
        consumer : Entity::User instance or Entity::Gp instance
        consumed : Entity::* instance
        method   : scalar (string) : method name

=cut

sub addPerm {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['consumer_id', 'consumed_id', 'method']);
    
    # TODO verifier que la methode donnée en argument exists sur l'entity
    # représentée par consumed_id

    $self->{schema}->resultset('Entityright')->find_or_create(
        { entityright_consumer_id => $args{consumer_id},
          entityright_consumed_id => $args{consumed_id},
          entityright_method => $args{method} },
    );
}

=head2 removePerm

=cut

sub removePerm {
    my $self = shift;
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

=head2 updatePerms

    desc : update all permissions methods 
    args: consumer_id, consumed_id, methods list
    
=cut

sub updatePerms {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['consumer_id', 'consumed_id', 'methods']);
    
    my $methods = $args{methods};
    # we remove actuals perms not in methods argument
    
    if ((@$methods[0]) eq "") {
        my $actualperms = $self->{schema}->resultset('Entityright')->search(
        {    entityright_consumer_id => $args{consumer_id},
             entityright_consumed_id => $args{consumed_id},
        },
        )->delete_all;
        last;
    }
    else{
        my $actualperms = $self->{schema}->resultset('Entityright')->search(
        {    entityright_consumer_id => $args{consumer_id},
             entityright_consumed_id => $args{consumed_id},
             entityright_method => { -not_in => @$methods },
        },
        )->delete_all;
    }   
 
    # we add new method perms if not already exists
    if (ref scalar(@$methods[0]) ne "ARRAY"){
    $methods = [$methods];
    }
    foreach my $m (@$methods) {	 
        for (my $i=0; $i<scalar(@$m); $i++){
            $self->{schema}->resultset('Entityright')->find_or_create(
            {   entityright_consumer_id => $args{consumer_id},
                entityright_consumed_id => $args{consumed_id},    
                entityright_method => $m->[$i],
            }
            );
        }   
    }
}

=head2 getGrantedMethods

    desc : given a consumer entity (user or user's group) and a consumed entity,
           return an array containing all granted methods for that consumer on this consumed. 
    args: consumer_id, consumed_id
    return : array of scalar (string methods name)

=cut 

sub getGrantedMethods {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['consumer_id', 'consumed_id']);
   
    my @methods = ();
    my $resultset = $self->{schema}->resultset('Entityright')->search(
        { entityright_consumer_id => $args{consumer_id},
          entityright_consumed_id => $args{consumed_id},
        },
        { columns => ['entityright_method']}
    );
    while(my $row = $resultset->next) {
        push @methods, $row->get_column('entityright_method');
    }
    return @methods;
}


1;
