#    Copyright © 2011-2013 Hedera Technology SAS
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

=pod
=begin classdoc

TODO

=end classdoc
=cut

package Entity::Component::Nfsd3;
use base Entity::Component;
use base Manager::ExportManager;

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Container;
use Entity::ContainerAccess;
use Entity::ContainerAccess::NfsContainerAccess;
use Entity::NfsContainerAccessClient;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";

use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    container_accesses => {
        label        => 'Exports',
        type         => 'relation',
        relation     => 'single_multi',
        is_mandatory => 0,
        is_editable  => 1,
        specialized  => 'NfsContainerAccess'
    },
    export_type => {
        is_virtual => 1
    }
};

sub getAttrDef { return ATTR_DEF; }


sub exportType {
    return "NFS export";
}

sub getConf {
    my $self = shift;

    my $conf = $self->toJSON(raw    => 1,
                             deep   => 1,
                             expand => [ 'container_accesses' ]);

    # Overrive the generic getConf as it handle one level of relations only.
    return $conf;
}


=pod
=begin classdoc

Return directory where a device will be mounted for nfs export.

=end classdoc
=cut

sub getMountDir {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container" ]);

    my $dev = $args{container}->container_device;
    if (! $args{container}->isa("Entity::Container::LocalContainer")) {
        $dev =~ s/.*\///g;
        return "/nfsexports/" . $dev;
    }

    return $dev;
}


=pod
=begin classdoc

This function a new client with options to an export.

=end classdoc
=cut

sub addExportClient {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "export_id", "client_name", "client_options" ]);

    my $exportclient = Entity::NfsContainerAccessClient->new(
                           name                    => $args{client_name},
                           options                 => $args{client_options},
                           nfs_container_access_id => $args{export_id}
                       );

    return $exportclient;
}


=pod
=begin classdoc

Return a data structure to pass to the template processor for /etc/exports file.

=end classdoc
=cut

sub getTemplateDataExports {
    my $self = shift;
    my $nfsd3_exports = [];

    my @exports = Entity::ContainerAccess::NfsContainerAccess->search(
                      hash => { export_manager_id => $self->id }
                  );

    for my $export (@exports) {
        my $clients = [];
        my $mountpoint = $self->getMountDir(container => $export->getContainer);
        my @clients = Entity::NfsContainerAccessClient->search(
                          hash => { nfs_container_access_id => $export->getAttr(name => "nfs_container_access_id") }
                      );

        for my $client(@clients) {
            push @{$clients}, {
                name    => $client->getAttr(name => 'name'),
                options => $client->getAttr(name => 'options')
            };
        }

        push @{$nfsd3_exports}, {
            clients => $clients,
            path    => $mountpoint
        };
    }

    return {
        nfsd3_exports => $nfsd3_exports
    };
}


=pod
=begin classdoc

Return a data structure to pass to the template processor for /etc/default/nfs-common file.

=end classdoc
=cut

sub getTemplateDataNfsCommon {
    my $self = shift;

    return {
        nfsd3_statdopts => $self->getAttr(name => 'nfsd3_statdopts'),
        nfsd3_need_gssd => $self->getAttr(name => 'nfsd3_need_gssd')
    };
}


=pod
=begin classdoc

Return a data structure to pass to the template processor
for /etc/default/nfs-kernel-server file.

=end classdoc
=cut

sub getTemplateDataNfsKernelServer {
    my $self = shift;

    return {
        nfsd3_rpcnfsdcount    => $self->getAttr(name => 'nfsd3_rpcnfsdcount'),
        nfsd3_rpcnfsdpriority => $self->getAttr(name => 'nfsd3_rpcnfsdpriority'),
        nfsd3_rpcmountopts    => $self->getAttr(name => 'nfsd3_rpcmountopts'),
        nfsd3_need_svcgssd    => $self->getAttr(name => 'nfsd3_need_svcgssd'),
        nfsd3_rpcsvcgssdopts  => $self->getAttr(name => 'nfsd3_rpcsvcgssdopts')
    }
}

sub getReadOnlyParameter {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'readonly' ]);
    
    return undef;
}


sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container", "client_name", "client_options" ]);

    $log->debug("New Operation CreateExport with attrs : " . %args);
    $self->service_provider->getManager(manager_type => 'ExecutionManager')->enqueue(
        type     => 'CreateExport',
        params   => {
            context => {
                export_manager => $self,
                container      => $args{container},
            },
            manager_params => {
                client_name    => $args{client_name},
                client_options => $args{client_options},
            },
        },
    );
}

sub getPuppetDefinition {
    my ($self, %args) = @_;

    return merge($self->SUPER::getPuppetDefinition(%args), {
        nfsd => {
            classes => {
                'kanopya::nfsd' => { }
            }
        }
    } );
}

1;
