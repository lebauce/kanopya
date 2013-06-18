# Openldap1.pm - Openldap1 component
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
# Created 4 sept 2010

package Entity::Component::Openldap1;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use General;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    openldap1_port      => { pattern        => '^\d*$',
                             is_mandatory   => 0,
                             is_extended    => 0,
                             is_editable    => 0
                           },
    openldap1_suffix    => { pattern        => '^.*$',
                             is_mandatory   => 0,
                             is_extended    => 0,
                             is_editable    => 0
                           },
    openldap1_directory => { pattern        => '^.*$',
                             is_mandatory   => 0,
                             is_extended    => 0,
                             is_editable    => 0
                           },
    openldap1_rootdn    => { pattern        => '^.*$',
                             is_mandatory   => 0,
                             is_extended    => 0,
                             is_editable    => 0
                           },
    openldap1_rootpw    => { pattern        => '^.*$',
                             is_mandatory   => 0,
                             is_extended    => 0,
                             is_editable    => 0
                           },
};

sub getAttrDef { return ATTR_DEF; }

sub getBaseConfiguration {
    return { 
        openldap1_port      => 389, 
        openldap1_suffix    => "dc=nodomain",
        openldap1_directory => "/var/lib/ldap",
        openldap1_rootdn    => "dc=admin,dc=nodomain",
        openldap1_rootpw    => undef
    };
}

sub getConf {
    my $self = shift;
    my $slapd_conf = {
        openldap1_id => undef,
        openldap1_port     =>    389, 
        openldap1_suffix =>    "dc=nodomain",
        openldap1_directory  =>    "/var/lib/ldap",
        openldap1_rootdn =>    "dc=admin,dc=nodomain",
        openldap1_rootpw => ""
    };
    
    my $confindb = $self->{_dbix};
    if($confindb) {
       $slapd_conf = {
         openldap1_id  => $confindb->get_column('openldap1_id'),
         openldap1_port   => $confindb->get_column('openldap1_port'),
         openldap1_suffix  => $confindb->get_column('openldap1_suffix'),
         openldap1_directory => $confindb->get_column('openldap1_directory'),
         openldap1_rootdn  => $confindb->get_column('openldap1_rootdn'),
         openldap1_rootpw  => $confindb->get_column('openldap1_rootpw')           
       };    
    }

    return $slapd_conf; 
}

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    my $conf = $args{conf};
    
    $conf->{openldap1_rootpw} = General::cryptPassword(password => $conf->{openldap1_rootpw});
    $self->{_dbix}->update($conf);
}    


sub getNetConf {
    my $self = shift;

    return {
        slapd => {
            port => $self->openldap1_port,
            protocols => ['tcp']
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        openldap => {
            manifest => $self->instanciatePuppetResource(
                            name => "kanopya::openldap",
                        )
        }
    } );
}

1;
