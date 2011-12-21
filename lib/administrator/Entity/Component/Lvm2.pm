# Lvm2.pm Logical volume manager component (Adminstrator side)
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
# Created 22 august 2010
=head1 NAME

<Entity::Component::Lvm2> <Lvm2 component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Lvm2> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Lvm2>;

my $component_instance_id = 2; # component instance id

Entity::Component::Lvm2->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Lvm2->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Lvm2 is class allowing to instantiate an Lvm2 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut

package Entity::Component::Lvm2;
use base "Entity::Component";


use strict;
use warnings;

use Kanopya::Exceptions;
use General;
use Log::Log4perl "get_logger";

use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

=head2 get
B<Class>   : Public
B<Desc>    : This method allows to get an existing Lvm2 component.
B<args>    : 
    B<component_instance_id> : I<Int> : identify component instance 
B<Return>  : a new Entity::Component::Lvm2 from Kanopya Database
B<Comment>  : To modify configuration use concrete class dedicated method
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
    
=cut

sub get {
    my $class = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required=>["id"]);

   my $self = $class->SUPER::get( %args, table=>"ComponentInstance");
   return $self;
}

=head2 new
B<Class>   : Public
B<Desc>    : This method allows to create a new instance of Storage component and concretly Lvm2.
B<args>    : 
    B<component_id> : I<Int> : Identify component. Refer to component identifier table
    B<cluster_id> : I<int> : Identify cluster owning the component instance
B<Return>  : a new Entity::Component::Lvm2 from parameters.
B<Comment>  : Like all component, instantiate it creates a new empty component instance.
        You have to populate it with dedicated methods.
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
    
=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args, required=>["cluster_id", "component_id"]);

    # We create a new DBIx containing new entity
    my $self = $class->SUPER::new( %args);

    return $self;

}

sub getMainVg{
    my $self = shift;
    my $vgname = $self->{_dbix}->lvm2_vgs->single->get_column('lvm2_vg_name');
    my $vgid = $self->{_dbix}->lvm2_vgs->single->get_column('lvm2_vg_id');
    $log->debug("Main VG founds, its id is <$vgid>");
    #TODO getMainVg, return id or name ?
    return {vgid => $vgid, vgname =>$vgname};
}

sub getVg {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args, required=>["lvm2_vg_id"]);

    return  $self->{_dbix}->lvm2_vgs->find($args{lvm2_vg_id})->get_column('lvm2_vg_name');
}

sub lvCreate{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args, required=>["lvm2_lv_name",
                                                  "lvm2_lv_size",
                                                  "lvm2_lv_filesystem",
                                                  "lvm2_vg_id"]);
    
    my ($value, $unit) = General::convertSizeFormat(size => $args{lvm2_lv_size});
    $args{lvm2_lv_size} = General::convertToBytes(value => $value, units => $unit);
    
    $log->debug("lvm2_lv_name is $args{lvm2_lv_name}, lvm2_lv_size is $args{lvm2_lv_size}, lvm2_lv_filesystem is $args{lvm2_lv_filesystem}, lvm2_vg_id is $args{lvm2_vg_id}");
    my $lv_rs = $self->{_dbix}->lvm2_vgs->single( {lvm2_vg_id => $args{lvm2_vg_id}})->lvm2_lvs;
    my $res = $lv_rs->create(\%args);
    
    $log->info("lvm2 logical volume $args{lvm2_lv_name} saved to database");
    return $res->get_column("lvm2_lv_id");
}

sub vgSizeUpdate{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args, required=>["lvm2_vg_id", "lvm2_vg_freespace"]);

    my $vg_rs = $self->{_dbix}->lvm2_vgs->single( {lvm2_vg_id => $args{lvm2_vg_id}});
    delete $args{lvm2_vg_id};
    $log->debug("Volume group freespace size update");
    return $vg_rs->update(\%args);
}

sub lvRemove{
    my $self = shift;
    my %args = @_;
    
General::checkParams(args=>\%args, required=>["lvm2_lv_name", "lvm2_vg_id"]);

# ICI Recuperer le bon vg et ensuite suivre le lien lv et new dedans
    $log->debug("lvm2_lv_name is $args{lvm2_lv_name}, lvm2_vg_id is $args{lvm2_vg_id}");
    my $lv_row = $self->{_dbix}->lvm2_vgs->find($args{lvm2_vg_id})->lvm2_lvs->single({lvm2_lv_name => $args{lvm2_lv_name}});
    $lv_row->delete();
    $log->info("lvm2 logical volume $args{lvm2_lv_name} deleted from database");
}

sub getConf {
    my $self = shift;

    my $conf = {};
    my $lineindb = $self->{_dbix}->lvm2_vgs->first;
    if(defined $lineindb) {
        my %dbconf = $lineindb->get_columns();
        $conf = \%dbconf;
        
        my $lv_rs = $lineindb->lvm2_lvs;
        my @tab_lv = ();
        while (my $lv_row = $lv_rs->next){
            my %lv = $lv_row->get_columns();
            delete $lv{'lvm2_vg_id'};
            push @tab_lv, \%lv;
        }
        $conf->{lvm2_lvs} = \@tab_lv;
    }
    
    return $conf;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;

    my $vg_id = $conf->{lvm2_vg_id};
    for my $new_lv ( @{ $conf->{lvm2_lvs} }) {
        $self->createLogicalVolume(    vg_id => $vg_id,
                                    disk_name => $new_lv->{lvm2_lv_name},
                                    size => $new_lv->{lvm2_lv_size},
                                    filesystem => $new_lv->{lvm2_lv_filesystem});
    }

}

sub createLogicalVolume {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required=>["disk_name", "size", "filesystem", "vg_id"]);
    my %params = $self->getAttrs();
    $log->debug("New Operation CreateLogicalVolume with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateLogicalVolume',
        params   => {
            component_instance_id => $self->getAttr(name=>'component_instance_id'),
            disk_name => $args{disk_name},
            size => $args{size},
            filesystem => $args{filesystem},
            vg_id => $args{vg_id}
        },
    );
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
