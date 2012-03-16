#    Copyright © 2011-2012 Hedera Technology SAS
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

package Entity::Component::Nfsd3;
use base "Entity::Component";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Administrator;

use Entity::Container;
use Entity::ContainerAccess::NfsContainerAccess;
use Entity::NfsContainerAccessClient;

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }

sub getExports {
    my $self = shift;
    my @result = ();

    if ($self->{_dbix}) {
        my @exports = Entity::ContainerAccess->search(
                          hash => { export_manager_id => $self->getAttr(name => "component_id") }
                      );

        for my $export (@exports) {
            my @clients = ();
            for my $client ($export->getClients()) {
                push @clients, {
                    nfsd3_exportclient_name    => $client->getAttr(name => 'name'),
                    nfsd3_exportclient_options => $client->getAttr(name => 'options'),
                };
            }
            push @result, {
                nfsd3_export_path => $export->getAttr(name => 'export_path'),
                clients     => \@clients,
            };
        }
    }
    return @result;
}

sub getConf {
    my $self = shift;
    my %conf = ( );

    if ($self->{_dbix}) {
        my @exports = $self->getExports();

        return {
            nfsd3_statdopts       => $self->getAttr(name => 'nfsd3_statdopts'),
            nfsd3_need_gssd       => $self->getAttr(name => 'nfsd3_need_gssd'),
            nfsd3_rpcnfsdcount    => $self->getAttr(name => 'nfsd3_rpcnfsdcount'),
            nfsd3_rpcnfsdpriority => $self->getAttr(name => 'nfsd3_rpcnfsdpriority'),
            nfsd3_rpcmountopts    => $self->getAttr(name => 'nfsd3_rpcmountopts'),
            nfsd3_need_svcgssd    => $self->getAttr(name => 'nfsd3_need_svcgssd'),
            nfsd3_rpcsvcgssdopts  => $self->getAttr(name => 'nfsd3_rpcsvcgssdopts'),
            exports               => \@exports
        };
    }
    else {
        return {
            nfsd3_statdopts       => '',
            nfsd3_need_gssd       => 'no',
            nfsd3_rpcnfsdcount    => '8',
            nfsd3_rpcnfsdpriority => '0',
            nfsd3_rpcmountopts    => '',
            nfsd3_need_svcgssd    => 'no',
            nfsd3_rpcsvcgssdopts  => '',
            exports               => []
        };
    }
}

sub setConf {
    my $self = shift;
    my($conf) = @_;

    for my $export ( @{ $conf->{exports} } ) {
        my @containers
            = Entity::Container->search(
                  hash => { service_provider_id => $self->getAttr(name => 'service_provider_id') }
              );

        # Check if specified device match to a registred container.
        my $container;
        my $device;
        foreach my $cont (@containers) {
            $device = $cont->getAttr(name => 'container_device');
            if ("$device" eq "$export->{nfsd3_export_path}") {
                $container = $cont;
                last;
            }
        }
        if (! defined $container) {
            $errmsg = "Specified device <$device> " .
                      "does not match to an existing container.";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }

        for my $client ( @{ $export->{clients} } ) {
            $self->createExport(export_name    => $export->{nfsd3_export_path},
								container      => $container,
                                client_name    => $client->{nfsd3_exportclient_name},
                                client_options => $client->{nfsd3_exportclient_options});
            last;
        }
    }
}

=head2 getMountDir
    
    Desc : Return directory where a device will be mounted for nfs export 
    args : device

=cut

sub getMountDir {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "device" ]);

    my $dev = $args{device};
    $dev =~ s/.*\///g;
    return "/nfsexports/" . $dev;
}

=head2 addExportClient
    
    Desc : This function a new client with options to an export.
    args : export_id, client_name, client_options

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

=head2 delExport
    
    Desc : This function delete an export from db

=cut

sub delExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "device" ]);

    my $export = Entity::ContainerAccess::NfsContainerAccess->find(
        hash => { export_path => $args{device} }
    );

    $export->delete();
}

=head2 getTemplateDataExports
    
    Desc : Return a data structure to pass to the template processor
           for /etc/exports file

=cut

sub getTemplateDataExports {
    my $self = shift;
    my $nfsd3_exports = [];

    my @exports = Entity::ContainerAccess->search(
                      hash => { export_manager_id => $self->getAttr(name => "component_id") }
                  );

    for my $export (@exports) {
        my $clients = [];
        my $mountpoint = $self->getMountDir(device => $export->getAttr(name => 'export_path'));
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

=head2 getTemplateDataNfsCommon
    
    Desc : Return a data structure to pass to the template processor
           for /etc/default/nfs-common file

=cut

sub getTemplateDataNfsCommon {
    my $self = shift;

    return {
        nfsd3_statdopts => $self->getAttr(name => 'nfsd3_statdopts'),
        nfsd3_need_gssd => $self->getAttr(name => 'nfsd3_need_gssd')
    };
}

=head2 getTemplateDataNfsKernelServer
    
    Desc : Return a data structure to pass to the template processor
           for /etc/default/nfs-kernel-server file
    
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

=head2 createExport
    
    Desc : Implement createExport from ExportManager interface.
           This function enqueue a ECreateExport operation.
    args : export_name, device, client_name, client_options
    
=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "export_name", "container",
                                       "client_name", "client_options" ]);

    my %params = $self->getAttrs();
    $log->debug("New Operation CreateExport with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateExport',
        params   => {
            storage_provider_id => $self->getAttr(name => 'service_provider_id'),
            export_manager_id   => $self->getAttr(name => 'component_id'),
            container_id   => $args{container}->getAttr(name => 'container_id'),
            export_name    => $args{export_name},
            client_name    => $args{client_name},
            client_options => $args{client_options},
        },
    );
}

=head2 removeExport

    Desc : Implement removeExport from ExportManager interface.
           This function enqueue a ERemoveExport operation.
    args : export_name

=cut

sub removeExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_access" ]);

    $log->debug("New Operation RemoveExport with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveExport',
        params   => {
            container_access_id => $args{container_access}->getAttr(name => 'container_id'),
        },
    );
}

=head2 getContainer

    Desc : Implement getContainerAccess from ExportManager interface.
           This function return the container access hash that match
           identifiers given in paramters.
    args : export_id

=cut

sub getContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_access" ]);

    my $export = $args{container_access};
    my $mountdir = $self->getMountDir(device => $export->getAttr(name => 'export_path'));

    # TODO: do not do this...
    # my @clients = $export->getClients();
    # my $options = $clients[0]->getAttr(name => "options");

    my $options = "ro";

    return {
        container_access_export  => $mountdir,
        container_access_options => $options,
        container_access_ip      => '10.0.0.1',
        container_access_port    => 2049
    };
}

=head2 addContainerAccess

    Desc : Implement addContainerAccess from ExportManager interface.
           This function create a new NfsContainerAccess into database.
    args : container, export_id

=cut

sub addContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container" ]);

    my $access = Entity::ContainerAccess::NfsContainerAccess->new(
                     container_id      => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id => $self->getAttr(name => 'nfsd3_id'),
                     export_path       => $args{container}->getAttr(name => 'container_device')
                 );

    my $access_id = $access->getAttr(name => 'container_access_id');
    $log->info("Nfs container access <$access_id> saved to database");

    return $access;
}

=head2 delContainerAccess

    Desc : Implement delContainerAccess from ExportManager interface.
           This function delete a NfsContainerAccess from database.
    args : container_access

=cut

sub delContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_access" ]);

    $args{container_access}->delete();
}

1;
