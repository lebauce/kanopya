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

my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }

sub getExports {
    my $self = shift;

    if ($self->{_dbix}) {
        my @result = ();
        my $exports = $self->{_dbix}->nfsd3_exports;
        while (my $export = $exports->next) {
            my $client_rs = $export->nfsd3_exportclients;
            my @clients = ();
            while (my $client = $client_rs->next) {
                push @clients, {
                    nfsd3_exportclient_name => $client->get_column('nfsd3_exportclient_name'),
                    nfsd3_exportclient_options => $client->get_column('nfsd3_exportclient_options'),
                }
            }
            push @result, {
                nfsd3_export_path => $export->get_column('nfsd3_export_path'),
                clients => \@clients,
            };
        }

		return @result;
	}
}

sub getConf {
    my $self = shift;
    my %conf = ( );
    
    my $conf_row = $self->{_dbix};
    if($conf_row) {
        $conf{nfsd3_statdopts} = $conf_row->get_column('nfsd3_statdopts');
        $conf{nfsd3_need_gssd} = $conf_row->get_column('nfsd3_need_gssd');
        $conf{nfsd3_rpcnfsdcount} = $conf_row->get_column('nfsd3_rpcnfsdcount');
        $conf{nfsd3_rpcnfsdpriority} = $conf_row->get_column('nfsd3_rpcnfsdpriority');
        $conf{nfsd3_rpcmountopts} = $conf_row->get_column('nfsd3_rpcmountopts');
        $conf{nfsd3_need_svcgssd} = $conf_row->get_column('nfsd3_need_svcgssd');
        $conf{nfsd3_rpcsvcgssdopts} = $conf_row->get_column('nfsd3_rpcsvcgssdopts');
        
        my @exports = $self->getExports();
        $conf{exports} = \@exports;
    }
    else {
        $conf{nfsd3_statdopts} = '';
        $conf{nfsd3_need_gssd} = 'no';
        $conf{nfsd3_rpcnfsdcount} = '8';
        $conf{nfsd3_rpcnfsdpriority} = '0';
        $conf{nfsd3_rpcmountopts} = '';
        $conf{nfsd3_need_svcgssd} = 'no';
        $conf{nfsd3_rpcsvcgssdopts} = '';
        $conf{exports} = [];
    }
    
    return \%conf;
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
        foreach my $cont (@containers) {
            my $device = $cont->getAttr(name => 'container_device');
            if ("$device" eq "$export->{nfsd3_export_path}") {
                $container = $cont;
                last;
            }
        }
        if (! defined $container) {
            $errmsg = "Specified device <$export->{nfsd3_export_path}> " .
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

#    my $self = shift;
#    my($conf) = @_;
#    
#    # delete old conf        
#    my $conf_row = $self->{_dbix};
#    $conf_row->delete() if (defined $conf_row); 
#
#    # create
#    $conf_row = $self->{_dbix}->create( {
#        nfsd3_statdopts => $conf->{nfsd3_statdopts},
#        nfsd3_need_gssd => $conf->{nfsd3_need_gssd},
#        nfsd3_rpcnfsdcount => $conf->{nfsd3_rpcnfsdcount},
#        nfsd3_rpcnfsdpriority => $conf->{nfsd3_rpcnfsdpriority},
#        nfsd3_rpcmountopts => $conf->{nfsd3_rpcmountopts},
#        nfsd3_need_svcgssd => $conf->{nfsd3_need_svcgssd},
#        nfsd3_rpcsvcgssdopts => $conf->{nfsd3_rpcsvcgssdopts},
#    } );
#    
#    # exports
#    foreach my $export (@{ $conf->{exports} }) {
#        my $export_row = $conf_row->nfsd3_exports->create({
#            nfsd3_export_path => $export->{nfsd3_export_path}
#        });
#        # clients options                                                        
#        foreach my $client (@{ $export->{clients} }) {
#            $export_row->nfsd3_exportclients->create(
#            {    
#                nfsd3_exportclient_name => $client->{nfsd3_exportclient_name},
#                nfsd3_exportclient_options => $client->{nfsd3_exportclient_options},
#            });
#        }    
#    } 

}

# return directory where a device will be mounted for nfs export 
sub getMountDir {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "device" ]);

    #my $dir = $args{device};
    #$dir =~ /^\/dev\/[\w-]+\/([\w-]+)$/;
    #return "/nfsexports/" . $1;

    my $dev = $args{device};
    $dev =~ s/.*\///g;
    return "/nfsexports/" . $dev
}

=head2 addExport
    
    Desc : This function add new export to the db component
    args : export_id, client_name, client_options 

=cut

sub addExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "device" ]);

    my $component = $self->{_dbix};
    my $export = $component->nfsd3_exports->create(
                     { nfsd3_export_path => $args{device} }
                 );

    $export->discard_changes;
    return $export->get_column('nfsd3_export_id')

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

    my $component = $self->{_dbix};
    my $exportclient_rs = $component->nfsd3_exports->single({nfsd3_export_id =>$args{export_id}})->nfsd3_exportclients;
    my $exportclient = $exportclient_rs->create(
                           { nfsd3_exportclient_name => $args{client_name},
                             nfsd3_exportclient_options => $args{client_options} }
                       );

    $exportclient->discard_changes;
    return $exportclient->get_column('nfsd3_exportclient_id')
}

=head2 removeExportClient
    
    Desc : This function delete a client from an export
    args : client_id

=cut

sub removeExportClient {
    my $self = shift;
    my %args  = @_;    
    if (! exists $args{client_id} or ! defined $args{client_id}) {
        $errmsg = "Component::Nfsd3->removeExportClient needs a client_id named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    #return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->delete();    
}


# return a data structure to pass to the template processor for /etc/exports file
sub getTemplateDataExports {
    my $self = shift;
    my $data = {};
    my $general_config = $self->{_dbix};
    if(not $general_config) {
        # TODO throw exception then no configuration
    } 
    
    $data->{nfsd3_exports} = [];
    my $exports_rs = $general_config->nfsd3_exports;
    while(my $export = $exports_rs->next) {
        my $record = {};
        $record->{path} = $self->getMountDir(device => $export->get_column('nfsd3_export_path'));
        $record->{clients} = [];
        my $clients_rs = $export->nfsd3_exportclients;
        while(my $client = $clients_rs->next) {
            my $tmp = {
                name => $client->get_column('nfsd3_exportclient_name'),
                options => $client->get_column('nfsd3_exportclient_options')
            };    
            push @{$record->{clients}}, $tmp;     
        }
        push @{$data->{nfsd3_exports}}, $record;     
    }
     return $data;
}

# return a data structure to pass to the template processor for /etc/default/nfs-common file
sub getTemplateDataNfsCommon {
    my $self = shift;
    my $data = {};
    my $general_config = $self->{_dbix};
    if(not $general_config) {
        # TODO throw exception then no configuration
    } 
    $data->{nfsd3_statdopts} = $general_config->get_column('nfsd3_statdopts');
    $data->{nfsd3_need_gssd} = $general_config->get_column('nfsd3_need_gssd');
    
    return $data;
}

# return a data structure to pass to the template processor for /etc/default/nfs-kernel-server file
sub getTemplateDataNfsKernelServer {
    my $self = shift;
    my $data = {};
    my $general_config = $self->{_dbix};
    if(not $general_config) {
        # TODO throw exception then no configuration
    } 
    $data->{nfsd3_rpcnfsdcount}    = $general_config->get_column('nfsd3_rpcnfsdcount');
    $data->{nfsd3_rpcnfsdpriority} = $general_config->get_column('nfsd3_rpcnfsdpriority');
    $data->{nfsd3_rpcmountopts}    = $general_config->get_column('nfsd3_rpcmountopts');
    $data->{nfsd3_need_svcgssd}    = $general_config->get_column('nfsd3_need_svcgssd');
    $data->{nfsd3_rpcsvcgssdopts}  = $general_config->get_column('nfsd3_rpcsvcgssdopts');
    
    return $data;   
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

    General::checkParams(args => \%args, required => [ "export_id", "client_id" ]);

    my $export_rs = $self->{_dbix}->nfsd3_exports->find($args{export_id});
    my $client_rs = $export_rs->nfsd3_exportclients->find($args{client_id});

    my $mountdir = $self->getMountDir(device => $export_rs->get_column('nfsd3_export_path'));
    my $container = {
        container_access_export  => $mountdir,
        container_access_options => $client_rs->get_column('nfsd3_exportclient_options'),
        container_access_ip      => '10.0.0.1',
        container_access_port    => 2049
    };

    return $container;
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
                         required => [ "container", "export_id", "client_id" ]);

    my $access = Entity::ContainerAccess::NfsContainerAccess->new(
                     container_id      => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id => $self->getAttr(name => 'nfsd3_id'),
                     export_id         => $args{export_id},
                     client_id         => $args{client_id},
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
