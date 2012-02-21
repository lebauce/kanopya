# ActiveDirectory.pm AD connector
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
# Created 24 july 2010

package Entity::Connector::ActiveDirectory;
use base "Entity::Connector";

use strict;
use warnings;
use Net::LDAP;
use Kanopya::Exceptions;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");


use constant ATTR_DEF => {
    ad_host => {    pattern        => '.*',
                    is_mandatory   => 1,
                    is_extended    => 0,
                    is_editable    => 0
                 },
    ad_user => {    pattern        => '.*',
                    is_mandatory   => 1,
                    is_extended    => 0,
                    is_editable    => 0
             },
    ad_pwd => {    pattern        => '.*',
                    is_mandatory   => 1,
                    is_extended    => 0,
                    is_editable    => 0
             },
    ad_nodes_base_dn => {    pattern        => '.*',
                    is_mandatory   => 0,
                    is_extended    => 0,
                    is_editable    => 0
             },

};

sub getAttrDef { return ATTR_DEF; }

sub getNodes {
    my $self = shift;
    

    my ($ad_host, $ad_user, $ad_pwd, $ad_nodes_base_dn) = (
        $self->getAttr(name => 'ad_host'),
        $self->getAttr(name => 'ad_user'),
        $self->getAttr(name => 'ad_pwd'),
        $self->getAttr(name => 'ad_nodes_base_dn'),
    );
    
    my $ldap = Net::LDAP->new( $ad_host ) or die "$@";
    my $mesg = $ldap->bind($ad_user, password => $ad_pwd);
    
    $mesg = $ldap->search(
        base => $ad_nodes_base_dn,
        filter => "cn=*",
        #base => "cn=computers,dc=hedera,dc=forest",
    );
    
    $mesg->code && die $mesg->error;
    
    my @nodes;
    for my $entry ($mesg->entries) {
        if (defined $entry->get_value('dNSHostName')) {
            push @nodes, {hostname => $entry->get_value('dNSHostName')};
        }
    }
    
    $mesg = $ldap->unbind;   # take down session
    
    return \@nodes;
}

1;