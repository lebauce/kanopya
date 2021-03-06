#    Copyright 2011-2013 Hedera Technology SAS
#
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

package Entity::Masterimage;
use base "Entity";

use strict;
use warnings;

use ClassType::ComponentType;

# Used to get the Kanopya cluster statically
# TODO: Implement a component KanopyaMasterimage of type MasterimageManager,
#       then the executor will be get by using the execution manager of
#       the cluster on which is installed the component
use Entity::ServiceProvider::Cluster;

use Log::Log4perl "get_logger";
use Data::Dumper;

use TryCatch;
my $err;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    masterimage_name => {
        pattern      => '^.+$',
        is_mandatory => 1,
    },
    masterimage_file => {
        pattern      => '^.+$',
        is_mandatory => 1,
    },
    masterimage_desc => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    masterimage_os => {
        pattern      => '^.+$',
        is_mandatory => 0,
    },
    masterimage_size => {
        pattern      => '^[0-9]+$',
        is_mandatory => 1,
    },
    masterimage_defaultkernel_id => {
        pattern      => '^[0-9]*$',
        is_mandatory => 0
    },
    components_provided => {
        type         => 'relation',
        relation     => 'multi',
        link_to      => 'component_type',
        is_mandatory => 0,
        is_editable  => 1,
    },
    storage_manager_id => {
        pattern      => '^.+$',
        is_mandatory => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub create {
    my $class = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'file_path' ],
                         optional => { 'keep_file' => 0 });

    if (! defined $args{storage_manager_id}) {
        $args{storage_manager_id} = Entity::Component::HCMStorageManager->find()->id;
    }

    # Get the deployment component on kanopya
    # TODO: Move this methode on the KanopyaDeploymentManager
    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster;
    $kanopya->getComponent(name => 'KanopyaDeploymentManager')->executor_component->enqueue(
        type   => 'DeployMasterimage',
        params => {
            file_path => $args{file_path},
            keep_file => $args{keep_file}
        }
    );
}

sub remove {
    my $self = shift;

    # Get the deployment component on kanopya
    # TODO: Move this methode on the KanopyaDeploymentManager
    my $kanopya = Entity::ServiceProvider::Cluster->getKanopyaCluster;
    $kanopya->getComponent(name => 'KanopyaDeploymentManager')->executor_component->enqueue(
        type     => 'RemoveMasterimage',
        params  => {
            context => {
                masterimage => $self
            }
        },
    );
}

sub setProvidedComponent {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'component_name', 'component_version' ]);

    my $component_type;
    try {
        $component_type = $self->masterimage_cluster_type->find(
                              related => 'component_types',
                              hash    => {
                                  component_name    => $args{component_name},
                                  component_version => $args{component_version},
                              }
                          );
    }
    catch ($err) {
        my $type_name = $self->masterimage_cluster_type->service_provider_name;
        $log->warn("Unable to set provided component <$args{component_name}$args{component_version}>, " .
                   "it seems to be not supported for the cluster type <$type_name>");
        return;
    }

    $self->update(components_provided => [ $component_type ], override_relations => 0);
}

1;
