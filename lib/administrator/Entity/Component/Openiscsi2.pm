# Openiscsi2.pm -open iscsi component (iscsi client) (Adminstrator side)
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
# Created 5 august 2010
=head1 NAME

<Entity::Component::Openiscsi2> <Openiscsi component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Openiscsi2> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Openiscsi2>;

my $component_instance_id = 2; # component instance id

Entity::Component::Openiscsi2->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Openiscsi2->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Openiscsi2 is class allowing to instantiate an Openiscsi component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut
package Entity::Component::Openiscsi2;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

sub getConf {
    my $self = shift;
    my %conf = ( );
    
    my $conf_rs = $self->{_dbix}->openiscsi2s;
    my @imports = ();
    while (my $conf_row = $conf_rs->next) {
        my %import = $conf_row->get_columns();
        delete $import{component_instance_id};
        push @imports, \%import;
    }
    
    $conf{imports} = \@imports;
    
    return \%conf;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;
    
    $self->{_dbix}->openiscsi2s->delete_all();
    
    for my $import ( @{ $conf->{imports} } ) {
        delete $import->{openiscsi2_id};
        $self->{_dbix}->openiscsi2s->create( $import );
    }
    
}

sub getExports {
    my $self = shift;
    my $export_rs = $self->{_dbix}->openiscsi2s;
    my @tab_exports =();
    my $i =0;
    while (my $export_row = $export_rs->next){
        my $export ={};
        $export->{name} = "device" . $i;
        $export->{target} = $export_row->get_column('openiscsi2_target');
        $export->{ip} = $export_row->get_column('openiscsi2_server');
        $export->{port} = $export_row->get_column('openiscsi2_port');
        $export->{mount_point} = $export_row->get_column('openiscsi2_mount_point');
        $export->{options} = $export_row->get_column('openiscsi2_mount_options');
        $export->{fs} = $export_row->get_column('openiscsi2_filesystem');
        $i++;
        push @tab_exports, $export;
    }
    $log->debug("asked openiscsi import : " . Dumper(@tab_exports));
    return \@tab_exports;
}

sub getExportsList {
    
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
