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
use Net::LDAPS;
use Kanopya::Exceptions;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");


use constant ATTR_DEF => {
    ad_host => {    pattern        => '.*',
                    is_mandatory   => 0,
                    is_extended    => 0,
                    is_editable    => 0
                 },
    ad_user => {    pattern        => '.*',
                    is_mandatory   => 0,
                    is_extended    => 0,
                    is_editable    => 0
             },
    ad_pwd => {     pattern        => '.*',
                    is_mandatory   => 0,
                    is_extended    => 0,
                    is_editable    => 0
             },
    ad_nodes_base_dn => {
                    pattern        => '.*',
                    is_mandatory   => 0,
                    is_extended    => 0,
                    is_editable    => 0
             },

};

sub getAttrDef { return ATTR_DEF; }

sub getNodes {
    my $self = shift;
    my %args = @_;
    
    return $self->retrieveNodes(
        ad_host             => $self->getAttr(name => 'ad_host'),
        ad_user             => $self->getAttr(name => 'ad_user'),
        #ad_pwd              => $self->getAttr(name => 'ad_pwd'), # Password is not stored in db but provided to the method
        ad_pwd              => $args{password},
        ad_nodes_base_dn    => $self->getAttr(name => 'ad_nodes_base_dn'),
        ad_usessl           => $self->getAttr(name => 'ad_usessl'),
    );
}

sub retrieveNodes {
    my $self = shift;
    my %args = @_;

    my ($ad_host, $ad_user, $ad_pwd, $ad_nodes_base_dn, $usessl) = (
        $args{'ad_host'},
        $args{'ad_user'},
        $args{'ad_pwd'},
        $args{'ad_nodes_base_dn'},
        $args{'ad_usessl'},
    );
    
    my $ldap_class = $usessl ? 'Net::LDAPS' : 'Net::LDAP';
    
    my $ldap = $ldap_class->new( $ad_host ) or throw Kanopya::Exception::Internal(error => "LDAP connection error: $@");
    my $mesg = $ldap->bind($ad_user, password => $ad_pwd);
    
    
    $mesg = $ldap->search(
        base => $ad_nodes_base_dn,
        filter => "cn=*",
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


sub checkConf {
    my $self = shift;
    my ($conf) = @_;
    
    my $nodes = $self->retrieveNodes(
        ad_host             => $conf->{ad_host},
        ad_user             => $conf->{ad_user},
        ad_pwd              => $conf->{ad_pwd},
        ad_nodes_base_dn    => $conf->{ad_nodes_base_dn},
    );
    
    my $node_count = scalar(@$nodes);
    
    return "Request success, $node_count node" . ($node_count > 1 ? 's' : '') . ' found in container';
}

1;