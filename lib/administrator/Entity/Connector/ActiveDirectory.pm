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
use base "Manager::DirectoryServiceManager";

use strict;
use warnings;
use Net::LDAPS;
use Kanopya::Exceptions;
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");


use constant ATTR_DEF => {
    ad_host => {    pattern        => '.*',
                    is_mandatory   => 0,
                    is_extended    => 0,
                    is_editable    => 1
                 },
    ad_user => {    pattern        => '.*',
                    is_mandatory   => 0,
                    is_extended    => 0,
                    is_editable    => 1
             },
    ad_pwd => {     pattern        => '.*',
                    is_mandatory   => 0,
                    is_extended    => 0,
                    is_editable    => 1
             },
    ad_usessl => {
      pattern       => '^[01]$',
      is_mandatory  => 0,
      is_extended   => 0,
      is_editable   => 1
    }

};

sub getAttrDef { return ATTR_DEF; }

sub _ldapObj {
    my $self = shift;
    my %args = @_;

    my ($ad_host, $ad_user, $ad_pwd, $usessl) = (
        $args{'ad_host'},
        $args{'ad_user'},
        $args{'ad_pwd'},
        $args{'ad_usessl'},
    );

    my $ldap_class = $usessl ? 'Net::LDAPS' : 'Net::LDAP';

    my $ldap = $ldap_class->new( $ad_host ) or throw Kanopya::Exception::Internal(error => "LDAP connection error: $@");
    my $mesg = $ldap->bind($ad_user, password => $ad_pwd);

    $mesg->code && throw Kanopya::Exception::Internal(error => "LDAP connection error. Invalid login/password. (" . ($mesg->error) . ")");

    return $ldap;
}

sub getNodes {
    my $self = shift;
    my %args = @_;

    my $ldap = $self->_ldapObj(
        ad_host             => $self->getAttr(name => 'ad_host'),
        ad_user             => $self->getAttr(name => 'ad_user'),
        ad_pwd              => $args{password},
        ad_usessl           => $self->getAttr(name => 'ad_usessl'),
    );

    return $self->retrieveNodes(
        ldap                => $ldap,
        ad_nodes_base_dn    => $args{ad_nodes_base_dn},
    );
}

=head2 getDirectoryTree

    desc: return all the tree of Container,OU and Group from AD root
    args: password
    returns:    [ ADnode, ...]
                with    ADnode = {
                            name => <node common name>,
                            dn => <node distinguished name>,
                            children => [ ADnode, ...]
                        }

=cut

sub getDirectoryTree {
    my $self = shift;
    my %args = @_;

    my $ldap = $self->_ldapObj(
        ad_host             => $self->getAttr(name => 'ad_host'),
        ad_user             => $self->getAttr(name => 'ad_user'),
        ad_pwd              => $args{password},
        ad_usessl           => $self->getAttr(name => 'ad_usessl'),
    );

    # get Root DN
    my $mesg = $ldap->search(
        base => '',
        scope => 'base',
        filter => 'cn=*'
    );

    my @entries = $mesg->entries;
    my $entry = shift @entries;
    my ($domain) = split(':', $entry->get_value('ldapServiceName'));
    my $root = $entry->get_value('rootDomainNamingContext');

    return [{
        name        => $domain,
        dn          => $root,
        children    => $self->_getTree(ldap => $ldap, base => $root)
    }];
}

sub _getTree {
    my $self = shift;
    my %args = @_;

    my $ldap = $args{ldap};

    my $mesg = $ldap->search(
        base => $args{base},
        scope => 'one',
        filter => "(|(objectClass=group)(objectClass=organizationalUnit)(objectClass=container))",
    );
    $mesg->code && die $mesg->error;

    my @tree;

    ENTRY:
    for my $entry ($mesg->entries) {
        my $advanced    = $entry->get_value('showInAdvancedViewOnly');
        my $dn          = $entry->get_value('distinguishedName');

        # Don't get advanced system containers
        next ENTRY if ( $advanced && $advanced eq 'TRUE' );

        # Keep only computer containers
        next ENTRY if ( $dn =~ 'CN=Users,.*' ||
                        $dn =~ 'CN=ForeignSecurityPrincipals,.*' ||
                        $dn =~ 'CN=Managed Service Accounts,.*' );

        my $elem = {
            name        => $entry->get_value('name'),
            dn          => $dn,
            children    => $self->_getTree(ldap => $ldap, base => $dn),
        };
        push @tree, $elem;
    }

    return \@tree;
}

sub retrieveNodes {
    my $self = shift;
    my %args = @_;

    my ($ldap, $ad_nodes_base_dn) = (
        $args{'ldap'},
        $args{'ad_nodes_base_dn'},
    );

    my $mesg = $ldap->search(
        base => $ad_nodes_base_dn,
        scope => 'base',
        filter => "cn=*",
    );

    $mesg->code && die $mesg->error;

    my $computers;
    my @entries = $mesg->entries;
    my $entry = shift @entries;
    #$entry->dump;
    my $objectCategory = $entry->get_value('objectCategory');
    if ($objectCategory =~ 'CN=Group,.*') { 
        # Group
        $computers = $self->_getComputersFromGroup(group_entry => $entry, ldap => $ldap);
    } else {
        # OU or Container
        $computers = $self->_getComputersFromContainer(cont_entry => $entry, ldap => $ldap);
    }

    my @nodes;
    foreach my $computer (@$computers) {
        push @nodes, {hostname => $computer->get_value('dNSHostName')};
    }

    $mesg = $ldap->unbind;   # take down session

    return \@nodes;
}

sub _getComputersFromGroup {
    my ($self, %args) = @_;

    my $entry = $args{group_entry};
    my $ldap = $args{ldap}; 

    my @computers;
    my @members = $entry->get_value('member');
    foreach my $member_dn (@members) {
        my $resp = $ldap->search(
                base => $member_dn,
                filter => "objectCategory=Computer",
        );
        for my $member ($resp->entries) {
            push @computers, $member;
        }
    }
    return \@computers;
}

sub _getComputersFromContainer {
    my ($self, %args) = @_;

    my $entry = $args{cont_entry};
    my $ldap = $args{ldap};
    
    my @computers;  
    my $resp = $ldap->search(
        base => $entry,
        scope => 'sub',
        filter => "objectCategory=Computer",
    );
    for my $member ($resp->entries) {
        push @computers, $member;
    }
    return \@computers; 
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