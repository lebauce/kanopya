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
package CapacityPlanning;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;

my $log = get_logger("orchestrator");

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {
        _model => undef,
        _constraints => undef,
        _nb_tiers => undef,
        _search_spaces => undef,
    };
    bless $self, $class;
    
    return $self;
}

sub setModel {    
    my $self = shift;
    my %args = @_;
    
    if (! defined $args{model}) { 
        my $errmsg = "needs a 'model' argument";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg); 
    }
    
    $self->{_model} = $args{model};
}

sub setConstraints {
    my $self = shift;
    my %args = @_;
    
    if (! defined $args{constraints}) { 
        my $errmsg = "needs a 'constraints' argument";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg); 
    }
    
    $self->{_constraints} = $args{constraints};    
}

sub setNbTiers {    
    my $self = shift;
    my %args = @_;
    
    if (! defined $args{tiers}) { 
        my $errmsg = "needs a 'tiers' argument";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg); 
    }
    
    $self->{_nb_tiers} = $args{tiers};
}

sub setSearchSpaceForTiers {
    my $self = shift;
    my %args = @_;
    
    if (! defined $args{search_spaces}) { 
        my $errmsg = "needs a 'search_spaces' argument";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg); 
    }
    
    $self->{_search_spaces} = $args{search_spaces};    
}

=head2 calculate
    
    Class : Public
    
    Desc :     Calculates an optimized configuration for 
             an Internet service, according to given constraints
    
    Args :
    
    Return :
    
=cut

sub calculate {
    my $self = shift;
    my %args = @_;
    
    # Check if good init
    for my $req ('model', 'constraints', 'nb_tiers', 'search_spaces' ) {
        if (not defined $self->{"_$req"} ) {
            throw Kanopya::Exception::Internal(error => "Bad capacity planning init: need to set '$req'");
        }
    }
    
    # params
    for my $req_param ('workload_amount', 'workload_class' ) {
        if (not defined $args{"$req_param"} ) {
            throw Kanopya::Exception::Internal::IncorrectParam(error => "Needs named argument '$req_param'");
        }
    }

    return $self->search( %args );
}


sub matchConstraints {    
    my $self = shift;
    my %args = @_;
 

     print "Perf: " . join( " | ", (map { "$_ => $args{perf}{$_}" } keys %{$args{perf}} ) ) . "\n";
    
    my $match = (     ($args{perf}{latency} <= $self->{_constraints}{max_latency}) &&
                    ($args{perf}{abort_rate} <= $self->{_constraints}{max_abort_rate}) );
    
    return $match;
}



1;