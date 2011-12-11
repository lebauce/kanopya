# Distribution.pm - This object allows to manipulate distribution configuration
#    Copyright  2011 Hedera Technology SAS
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
# Created 3 july 2010
package Entity::Distribution;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Component;
use Data::Dumper;
use Administrator;
use General;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    distribution_name => {pattern => '^[a-zA-Z]*$', is_mandatory => 1, is_extended => 0},
    distribution_version => {pattern => '^[0-9\.]+$', is_mandatory => 1, is_extended => 0},
    distribution_desc => {pattern => '^[\w\s]*$', is_mandatory => 0, is_extended => 0},
    etc_device_id => {pattern => '^[0-9\.]*$', is_mandatory => 0, is_extended => 0},
    root_device_id => {pattern => '^[0-9\.]*$', is_mandatory => 0, is_extended => 0}
};
sub getAttrDef{
    return ATTR_DEF;
}

sub methods {
    return {
        'get'        => {'description' => 'view this distribution', 
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this distribution', 
                        'perm_holder' => 'entity',
        },
    };
}

=head2 get

=cut

sub get {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);
   
    my $adm = Administrator->new();
    my $dbix_distribution = $adm->{db}->resultset('Distribution')->find($args{id});
    if(not defined $dbix_distribution) {
        $errmsg = "Entity::Distribution->get : id <$args{id}> not found !";    
     $log->error($errmsg);
     throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }       
       
       my $entity_id = $dbix_distribution->entitylink->get_column('entity_id');
       my $granted = $adm->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
       if(not $granted) {
           $errmsg = "Permission denied to get distribution with id $args{id}";
           $log->error($errmsg);
           throw Kanopya::Exception::Permission::Denied(error => $errmsg);
       }
       
       my $self = $class->SUPER::get( %args,  table => "Distribution");
       return $self;
}

=head2 getDistributions

=cut

sub getDistributions {
    my $class = shift;
    my %args = @_;
    my @objs = ();
    my ($rs, $entity_class);

    General::checkParams(args => \%args, required => ['hash']);

    my $adm = Administrator->new();
    return $class->SUPER::getEntities( %args,  type => "Distribution");
}

=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Check attrs ad throw exception if attrs missed or incorrect
    my $attrs = $class->checkAttrs(attrs => \%args);
    
    # We create a new DBIx containing new entity (only global attrs)
    my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Distribution");
    
    # Set the extended parameters
    $self->{_ext_attrs} = $attrs->{extended};

    return $self;

}

=head getDevices 

get etc and root device attributes for this distribution

=cut

sub getDevices {
    my $self = shift;
    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Distribution->getDevices must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    
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
    $log->info("Distribution etc and root devices retrieved from database");
    return $devices;
}

=head getProvidedComponents

get components provided by this distribution
return array ref containing hash ref 

=cut

sub getProvidedComponents {
    my $self = shift;
    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Distribution->getComponents must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    my $components = [];
    my $search = $self->{_dbix}->components_provided->search(undef, 
        { '+columns' => {'component_id' => 'component.component_id', 
                         'component_name' => 'component.component_name', 
                         'component_version' => 'component.component_version', 
                         'component_category' => 'component.component_category' },
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

=head updateProvidedComponents

update components provided by this distribution

=cut

sub updateProvidedComponents {
    my $self = shift;
    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Distribution->updateProvidedComponents must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    my $components = Entity::Component->getComponents();
    foreach my $c (@$components) {
		$self->{_dbix}->components_provided->find_or_create({component_id => $c->{component_id}});
	}
}



=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('distribution_name')." ".$self->{_dbix}->get_column('distribution_version');
    return $string;
}
1;
