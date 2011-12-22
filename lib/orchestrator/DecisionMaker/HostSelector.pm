# HostSelector.pm - Select better fit host according to context, constraints and choice policy

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

package DecisionMaker::HostSelector;

use strict;
use warnings;
use Kanopya::Exceptions;
use General;
use Entity::Host;
use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("orchestrator");

=head2 getHost
    
    Class : Public
    
    Desc :  Select and return the more suitable host according to constraints
     
    Args :  cluster_id : id of the cluster requesting a host
            
            CONSTRAINTS
            type :  array ref of host type ordered by preference
                    type can be 'phys' or 'virt'
            core : min number of desired core
            ram  : min amount of desired ram                                    # TODO manage unit (M,G,..)
            cloud_cluster_id : id of the cluster to use for virt host
            
            All constraints args are optional, not defined means no constraint for this arg
            Final constraints are intersection of input constraints and cluster components contraints.
            
    Return : Entity::Host
    
=cut

sub getHost {
    my $self = shift;
    my %args = @_;
    my ($default_core, $default_ram) = (1,"512M");

    General::checkParams(args => \%args, required => ["cluster_id"]);
    
    my %type_handlers = ('phys' => \&getPhysicalHost, 'virt' => \&getVirtualHost );
    my @type_list = defined $args{type} ? ($args{type}) : (keys %type_handlers); 
    delete $args{type};

    # Set default Ram and convert in B.
    my $ram = defined $args{ram} ? $args{ram} : $default_ram;
    my ($value, $unit) = General::convertSizeFormat(size => $ram);
    $args{ram} = General::convertToBytes(value => $value, units => $unit);
    
    # Set default core
    $args{core} = $default_core if (not defined $args{core});

    TYPE:
    for my $type (@type_list) {
        unless ( exists $type_handlers{$type} ) {
            $log->error("Unknown required host type: '$type'");
            next TYPE;
        }
        my $host_id = eval {
            return $type_handlers{$type}( $self, %args );
        };
        if ($@) {
            $log->debug($@->message);
            next TYPE;
        }
        return $host_id;
    }
    
    my $errmsg = "no free host respecting constraints";
    throw Kanopya::Exception::Internal(error => $errmsg);
}

sub _matchHostConstraints {
    my $self = shift;
    my %args = @_;
    
    my $host = $args{host};
    
    for my $constraint ('core', 'ram') {
        if (defined $args{$constraint}) {
            my $host_value = $host->getAttr( name => "host_$constraint");
            $log->debug("constraint '$constraint' ($host_value) >= $args{$constraint}");
            if ($host_value < $args{$constraint}) {
                return 0;
            }
        }
    }
    
    return 1;
}

sub getPhysicalHost {
    my $self = shift;
    my %args = @_;
    
    $log->info( "Looking for a physical host" );
    print Dumper \%args;
    
    # Get all free hosts
    my @free_hosts = Entity::Host->getFreeHosts();
    
    # Keep only hosts matching constraints (cpu,mem)
    my @valid_hosts = grep { $self->_matchHostConstraints( host => $_, %args ) } @free_hosts;
    
    if ( scalar @valid_hosts == 0) {
        my $errmsg = "no free physical host respecting constraints";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    # Get the first valid host
    # TODO get the better hosts according to rank (e.g min consumption, max cpu, ...)
    my $host = $valid_hosts[0];

    return $host->getAttr(name => 'host_id');
}

sub getVirtualHost {
    my $self = shift;
    my %args = @_;
    
    $log->info( "Looking for a virtual host" );
    
    my @clusters = @{$args{clusters}};
    CLUSTER:                
    for my $cluster (@clusters) {
        my $components = $cluster->getComponents( category => 'Cloudmanager');
        next CLUSTER if (0 == keys %$components);
        my $cm_component = (values %$components)[0];
        my $host_id = eval {
            return $cm_component->createHost(
                core => $args{core},
                ram => $args{ram},
            );
        };
        if ($@) {
            # We can't create virtual host for some reasons (e.g can't meet constraints)
            $log->debug($@->message);
            next CLUSTER;
        }
        return $host_id;
    }

    my $errmsg = "can't create a virtual host";
    throw Kanopya::Exception::Internal(error => $errmsg);
}

1;