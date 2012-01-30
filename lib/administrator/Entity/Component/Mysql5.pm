# Mysql5.pm - Mysql 5 component module (Adminstrator side)
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
# Created 12 sept 2010
=head1 NAME

<Entity::Component::Mysql5> <Mysql5 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Mysql5> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Mysql5>;

my $component_instance_id = 2; # component instance id

Entity::Component::Mysql5->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Mysql5->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Mysql5 is class allowing to instantiate an Mysql5 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Mysql5;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
	mysql5_port        => { pattern        => '^\d*$',
                            is_mandatory   => 0,
                            is_extended    => 0,
                            is_editable    => 0
                          },
    mysql5_datadir     => { pattern        => '^.*$',
                            is_mandatory   => 0,
                            is_extended    => 0,
                            is_editable    => 0
                          },
    mysql5_bindaddress => { pattern        => '^.*$',
                            is_mandatory   => 0,
                            is_extended    => 0,
                            is_editable    => 0
                          },
};

sub getAttrDef { return ATTR_DEF; }

sub getBaseConfiguration {
    return {
        mysql5_port => 3306,
        mysql5_datadir => "/var/lib/mysql",
        mysql5_bindaddress => '127.0.0.1'
    };
}

sub getConf {
    my $self = shift;
    my $mysql5_conf = {
        mysql5_id => undef,
        mysql5_port => 3306,
        mysql5_datadir => "/var/lib/mysql",
        mysql5_bindaddress => '127.0.0.1'
    };
    
    my $confindb = $self->{_dbix};
    if($confindb) {
       $mysql5_conf = {
           mysql5_id => $confindb->get_column('mysql5_id'),
           mysql5_port => $confindb->get_column('mysql5_port'),
           mysql5_datadir => $confindb->get_column('mysql5_datadir'),
           mysql5_bindaddress => $confindb->get_column('mysql5_bindaddress'),
       };    
    }
    return $mysql5_conf; 
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;
        
    if(not $conf->{mysql5_id}) {
        # new configuration -> create
        $self->{_dbix}->create($conf);
    } else {
        # old configuration -> update
        $self->{_dbix}->update($conf);
    }
}

sub getNetConf {
    my $self = shift;
    my $port = $self->{_dbix}->get_column('mysql5_port');
    return { $port => ['tcp'] };
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;
