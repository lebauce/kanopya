# General.pm - This lib contain general function used in microCluster system

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

General - Common Lib

=head1 SYNOPSIS

    use General;
    
    # Get EEntity Location from Entity
    my $execloc = General::getLocEEntityFromEntity($entity : Entity);
    
    # Get EEntity Class name from Entity
    my $execclass = General::getClassEEntityFromEntity($entity : Entity);


=head1 DESCRIPTION

Executor is the main object use to create execution objects

=head1 METHODS

=cut
package General;
use lib ".";
use McsExceptions;
use Log::Log4perl "get_logger";
my $log = get_logger("executor");

sub getClassEEntityFromEntity{
	my %args = @_;
	my $data = $args{entity};
	$log->trace("Try to get Eentity class from object". ref($data));
	$log->trace("Exist args_data " . exists($args{entity}) ."and isa ".$data->isa('Entity'));
	throw Mcs::Exception::Internal(error => "Try to get Eentity class from object not entity : ". ref($args{entity})) if (
													(! exists($args{entity})) or
													(! $data->isa('Entity')));
	my $entityclass = ref($args{entity});
	$log->debug("new operation inserted with his entity relation.");
    my $class = $entityclass;
	
    $class =~s/\:\:/\:\:E/g;
    $class = "E".$class;
    return $class;
    my $location = $class;
    $location =~s/\:\:/\//g;
    require $location . ".pm";
}

#TODO Tester si les regexp fonctionne en simulant le use.
sub getLocFromClass{
	my %args = @_;
	my $data = $args{entityclass};
	$log->warn("Try to get Location from class $data");
	my $location = $args{entityclass};
    $location =~ s/\:\:/\//g;
    return $location . ".pm";
}

1;