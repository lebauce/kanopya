# Systemimage.pm - This object allows to manipulate Systemimage configuration
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
# Created 17 july 2010
package Entity::Systemimage;
use base "Entity";

use strict;
use warnings;
use Kanopya::Exceptions;
use Administrator;
use Operation;
use Log::Log4perl "get_logger";
use Data::Dumper;
use General;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    systemimage_name => { pattern => '^[1-9a-zA-Z]*$',
                          is_mandatory => 1,
                          is_extended => 0 },
    
    systemimage_desc => { pattern => '^\w*$',
                          is_mandatory => 1,
                          is_extended => 0 },
    systemimage_dedicated => { pattern => '^(0|1)$',
                          is_mandatory => 0,
                          is_extended => 0 },
    
    distribution_id => { pattern => '^\d*$',
                         is_mandatory => 1,
                         is_extended => 0 },
                         
    etc_device_id => { pattern => '^\d*$',
                         is_mandatory => 0,
                         is_extended => 0 },
    
    root_device_id => { pattern => '^\d*$',
                         is_mandatory => 0,
                         is_extended => 0 },        
                         
    active => { pattern => '^[01]$',
                is_mandatory => 0,
                is_extended => 0 },        
};

sub methods {
    return {
        'create'    => {'description' => 'create a new system image', 
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this system image', 
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this system image', 
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this system image', 
                        'perm_holder' => 'entity',
        },
        'activate'=> {'description' => 'activate this system image', 
                        'perm_holder' => 'entity',
        },
        'deactivate'=> {'description' => 'deactivate this system image', 
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this system image', 
                        'perm_holder' => 'entity',
        },
    };
}

=head2 get

    Class: public
    desc: retrieve a stored Entity::Systemimage instance
    args:
        id : scalar(int) : user id
    return: Entity::Systemimage instance 

=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
        $errmsg = "Entity::SystemImage->get need an id named argument!";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
       
       my $adm = Administrator->new();
       my $dbix_systemimage = $adm->{db}->resultset('Systemimage')->find($args{id});
       if(not defined $dbix_systemimage) {
           $errmsg = "Entity::Systemiamge->get : id <$args{id}> not found !";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
       }       
       
       my $entity_id = $dbix_systemimage->entitylink->get_column('entity_id');
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
       if(not $granted) {
           $errmsg = "Permission denied to get system image with id $args{id}";
           $log->error($errmsg);
           throw Kanopya::Exception::Permission::Denied(error => $errmsg);
       }
       
       my $self = $class->SUPER::get( %args, table=>"Systemimage");
       return $self;
}

=head2 getSystemimages

    Class: public
    desc: retrieve several Entity::Systemimage instances
    args:
        hash : hashref : where criteria
    return: @ : array of Entity::Systemimage instances
    
=cut

sub getSystemimages {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{hash} or ! defined $args{hash})) { 
        $errmsg = "Entity::getSystemimage need a hash named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $adm = Administrator->new();
       return $class->SUPER::getEntities( %args,  type => "Systemimage");
}

sub getSystemimage {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{hash} or ! defined $args{hash})) { 
        $errmsg = "Entity::getSystemimage need a hash named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
       my @systemimages = $class->SUPER::getEntities( %args,  type => "Systemimage");
    return pop @systemimages;
}

=head2 new

    Public class method
    desc:  Constructor
    args: 
    return: Entity::Systemimage instance 
    
=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Check attrs ad throw exception if attrs missed or incorrect
    my $attrs = $class->checkAttrs(attrs => \%args);
    
    # We create a new DBIx containing new entity (only global attrs)
    my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Systemimage");
    
    # Set the extended parameters
    $self->{_ext_attrs} = $attrs->{extended};
    return $self;
}

=head2 create

=cut

sub create {
    my $self = shift;
    my %params = $self->getAttrs();
    my $admin = Administrator->new();
    my $mastergroup_eid = $self->getMasterGroupEid();
       my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $mastergroup_eid, method => 'create');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to create a new system image");
       }
    
    $log->debug("New Operation AddSystemimage with attrs : " . Dumper(%params));
    Operation->enqueue(
        priority => 200,
        type     => 'AddSystemimage',
        params   => \%params,
    );
}

=head2 installComponent

=cut

sub installComponent {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args,required=>["component_id"]);
    
    my %params = ();
    $params{systemimage_id} = $self->getAttr(name => 'systemimage_id');
    $params{component_id} = $args{component_id};
    
    $log->debug("New Operation InstallComponentOnSystemImage with attrs : " . Dumper(%params));
    Operation->enqueue(
        priority => 200,
        type     => 'InstallComponentOnSystemImage',
        params   => \%params,
    );
}

sub installedComponentLinkCreation {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args,required=>["component_id"]);
    $args{systemimage_id} = $self->getAttr(name=>"systemimage_id");
    $self->{_dbix}->components_installed->create(\%args);
}

=head2 update

=cut

sub update {
    my $self = shift;
    my $adm = Administrator->new();
    # update method concerns an existing entity so we use his entity_id
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $self->{_entity_id}, method => 'update');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to update this entity");
       }
    # TODO update implementation
}

=head2 remove

=cut

sub remove {
    my $self = shift;
    
    $log->debug("New Operation RemoveSystemimage with systemimage_id : <".$self->getAttr(name=>"systemimage_id").">");
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveSystemimage',
        params   => {systemimage_id => $self->getAttr(name=>"systemimage_id")},
    );
}

sub getAttrDef{
    return ATTR_DEF;
}

sub clone {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args,required=>["systemimage_name", "systemimage_desc"]);

    my $sysimg_id = $self->getAttr(name => 'systemimage_id');
    if (! defined $sysimg_id) {
        $errmsg = "Entity::Systemimage->clone needs a distribution_id parameter!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    $args{systemimage_id} = $sysimg_id;
    $log->debug("New Operation CloneSystemimage with attrs : " . Dumper(%args));
    Operation->enqueue(priority => 200,
                   type     => 'CloneSystemimage',
                   params   => \%args);
       
}

sub activate{
    my $self = shift;
    
    my  $adm = Administrator->new();
    $log->debug("New Operation ActivateSystemimage with systemimage_id : " . $self->getAttr(name=>'systemimage_id'));
    Operation->enqueue(priority => 200,
                   type     => 'ActivateSystemimage',
                   params   => {systemimage_id => $self->getAttr(name=>'systemimage_id')});
}

sub deactivate{
    my $self = shift;
    
    my  $adm = Administrator->new();
    $log->debug("New Operation DeactivateSystemimage with systemimage_id : " . $self->getAttr(name=>'systemimage_id'));
    Operation->enqueue(priority => 200,
                   type     => 'DeactivateSystemimage',
                   params   => {systemimage_id => $self->getAttr(name=>'systemimage_id')});
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('systemimage_name');
    return $string;
}

=head2 getDevices 

get etc and root device attributes for this systemimage

=cut

sub getDevices {
    my $self = shift;
    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Systemimage->getDevices must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    $log->info("retrieve etc and root devices attributes");
    my $etcrow = $self->{_dbix}->etc_device;
    my $rootrow = $self->{_dbix}->root_device;
    my $devices = {
        etc => { lv_id => $etcrow->get_column('lvm2_lv_id'), 
                 lvname => $etcrow->get_column('lvm2_lv_name'),
                 lvsize => $etcrow->get_column('lvm2_lv_size'),
                 lvfreespace => $etcrow->get_column('lvm2_lv_freespace'),    
                 filesystem => $etcrow->get_column('lvm2_lv_filesystem'),
                 vg_id => $etcrow->get_column('lvm2_vg_id'),
                 vgname => $etcrow->lvm2_vg->get_column('lvm2_vg_name'),
                 vgsize => $etcrow->lvm2_vg->get_column('lvm2_vg_size'),
                 vgfreespace => $etcrow->lvm2_vg->get_column('lvm2_vg_freespace'),
                },
        root => { lv_id => $rootrow->get_column('lvm2_lv_id'), 
                 lvname => $rootrow->get_column('lvm2_lv_name'),
                 lvsize => $rootrow->get_column('lvm2_lv_size'),
                 lvfreespace => $rootrow->get_column('lvm2_lv_freespace'),    
                 filesystem => $rootrow->get_column('lvm2_lv_filesystem'),
                 vg_id => $rootrow->get_column('lvm2_vg_id'),
                 vgname => $rootrow->lvm2_vg->get_column('lvm2_vg_name'),
                 vgsize => $rootrow->lvm2_vg->get_column('lvm2_vg_size'),
                 vgfreespace => $rootrow->lvm2_vg->get_column('lvm2_vg_freespace'),
        }
    };
    $log->info("Systemimage etc and root devices retrieved from database");
    return $devices;
}

=head2 getInstalledComponents

get components installed on this systemimage
return array ref containing hash ref 

=cut

sub getInstalledComponents {
    my $self = shift;
    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Systemimage->getComponents must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    my $components = [];
    my $search = $self->{_dbix}->components_installed->search(undef, 
        { '+columns' => [ 'component.component_id', 
                        'component.component_name', 
                        'component.component_version', 
                        'component.component_category' ],
            join => ['component'] } 
    );
    while (my $row = $search->next) {
        my $tmp = {};
        $tmp->{component_id} = $row->get_column('component_id');
        $tmp->{component_name} = $row->get_column('component_name');
        $tmp->{component_version} = $row->get_column('component_version');
        $tmp->{component_category} = $row->get_column('component_category');
        push @$components, $tmp;
    }
    return $components;
}

=head2 cloneComponentsInstalledFrom

# used during systemimage clone to set components installed on the new systemimage

=cut

sub cloneComponentsInstalledFrom {
    my $self = shift;
    my %args = @_;
    
    
    if(! exists $args{systemimage_source_id} or ! defined $args{systemimage_source_id}) {
        $errmsg = "Entity::Systemimage->cloneComponentsInstalled needs a systemimage_source_id parameter!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $si_source = Entity::Systemimage->get(id => $args{systemimage_source_id});
    my $rs = $si_source->{_dbix}->components_installed->search;
    while(my $component = $rs->next) {
        $self->{_dbix}->components_installed->create(
            {    component_id => $component->get_column('component_id') });    
    }
}

1;
