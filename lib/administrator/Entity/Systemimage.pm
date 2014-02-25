# Systemimage.pm - This object allows to manipulate Systemimage configuration
#    Copyright 2011 Hedera Technology SAS
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
use General;

use Entity::Container;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    systemimage_name => {
        pattern      => '^[0-9a-zA-Z_]*$',
        is_mandatory => 1,
    },
    systemimage_desc => {
        pattern      => '^.*$',
        is_mandatory => 1,
    },
    service_provider_id => {
        type         => 'relation',
        relation     => 'single',
        pattern      => '\d+',
        is_mandatory => 1,
    },
    active => {
        pattern      => '^[01]$',
        is_mandatory => 0,
    },
    systemimage_container_accesses => {
        label        => 'Container accesses',
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'container_access',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef{ return ATTR_DEF; }

sub methods {
    return {
        activate => {
            description => 'activate this system image', 
            perm_holder => 'entity',
        },
        deactivate => {
            description => 'deactivate this system image', 
            perm_holder => 'entity',
        },
    };
}

sub installedComponentLinkCreation {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args=>\%args,required=>["component_type_id"]);
    
    $args{systemimage_id} = $self->getAttr(name=>"systemimage_id");
    $self->{_dbix}->components_installed->create(\%args);
}


sub remove {
    my $self = shift;
    
    $log->debug("New Operation RemoveSystemimage with id : <" . $self->id . ">");

    # Use the execution manager of the service on which the disk manager is installed
    my $diskmanager = $self->getContainer->disk_manager;
    my $executor = $diskmanager->service_provider->getManager(manager_type => 'ExecutionManager');
    $executor->enqueue(
        type     => 'RemoveSystemimage',
        params   => {
            context => {
                systemimage => $self,
            }
        }
    );
}

sub toString {
    my $self = shift;

    return $self->systemimage_name;
}


sub getInstalledComponents {
    my $self = shift;
    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Systemimage->getInstalledComponents must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    my $components = [];
    my $search = $self->{_dbix}->components_installed->search(undef, 
        { '+columns' => {'component_name' => 'component_type.component_name', 
                         'component_version' => 'component_type.component_version', 
                         'component_category' => 'component_type.component_category' },
            join => ['component_type'] } 
    );
    while (my $row = $search->next) {
        my $tmp = {};
        $tmp->{component_type_id} = $row->get_column('component_type_id');
        $tmp->{component_name} = $row->get_column('component_name');
        $tmp->{component_version} = $row->get_column('component_version');
        $tmp->{component_category} = $row->get_column('component_category');
        push @$components, $tmp;
    }
    $log->debug('systemimage components:'.Dumper($components));
    return $components;
}


sub cloneComponentsInstalledFrom {
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['systemimage_source_id']);

    my $si_source = Entity::Systemimage->get(id => $args{systemimage_source_id});
    my $rs = $si_source->{_dbix}->components_installed->search;
    while(my $component = $rs->next) {
        $self->{_dbix}->components_installed->create(
            {    component_type_id => $component->get_column('component_type_id') });    
    }
}

sub getContainer {
    my $self = shift;

    my @accesses = $self->systemimage_container_accesses;
    if (@accesses) {
        return $accesses[0]->container_access->container;
    }

    throw Kanopya::Exception::Internal::NotFound(error => 'No container access found');
}

1;
