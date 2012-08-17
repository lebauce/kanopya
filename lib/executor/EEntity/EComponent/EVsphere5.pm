#    Copyright © 2011-2012 Hedera Technology SAS
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

package EEntity::EComponent::EVsphere5;

use base "EEntity::EComponent";
use base "EManager::EHostManager";

use strict;
use warnings;

use VMware::VIRuntime;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;

my $log = get_logger("executor");
my $errmsg;

###############################
# component interface methods #
###############################

=head2 connect

    Desc: Connect to a vCenter instance
    Args: $login, $pwd
    
=cut

sub connect {
    my ($self,%args) = @_; 

    General::checkParams(args => \%args, required => ['user_name', 'password', 'url']);

    eval {
        Util::connect($args{url}, $args{user_name}, $args{password});
    };  
    if ($@) {
        $errmsg = 'Could not connect to vCenter server: '.$@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }    
}

=head2 disconnect                                                                                                                                                                                                 
    Desc: End the vSphere session

=cut

sub disconnect {
    eval {
        Util::disconnect();
    };  
    if ($@) {
        $errmsg = 'Could not disconnect to vCenter server: '.$@;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }   
}   

1;
