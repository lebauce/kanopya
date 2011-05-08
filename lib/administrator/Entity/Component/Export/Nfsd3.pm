# Nfsd3.pm -NFS server 3 server component (Adminstrator side)
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

package Entity::Component::Export::Nfsd3;
use base "Entity::Component::Export";

use strict;
use warnings;

use Kanopya::Exceptions;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Administrator;

my $log = get_logger("administrator");
my $errmsg;

=head2 get

B<Class>   : Public
B<Desc>    : This method allows to get an existing NFSd component.
B<args>    : 
    B<component_instance_id> : I<Int> : identify component instance 
B<Return>  : a new Entity::Component::Export::Nfsd3 from Kanopya Database
B<Comment>  : To modify configuration use concrete class dedicated method
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
    
=cut

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
        $errmsg = "Entity::Component::Export::Nfsd31->get need an id named argument!";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
   my $self = $class->SUPER::get( %args, table=>"ComponentInstance");
   return $self;
}

=head2 new
B<Class>   : Public
B<Desc>    : This method allows to create a new instance of Export component and concretly Nfsd3.
B<args>    : 
    B<component_id> : I<Int> : Identify component. Refer to component identifier table
    B<cluster_id> : I<int> : Identify cluster owning the component instance
B<Return>  : a new Entity::Component::Export::Nfsd3 from parameters.
B<Comment>  : Like all component, instantiate it creates a new empty component instance.
        You have to populate it with dedicated methods.
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    if ((! exists $args{cluster_id} or ! defined $args{cluster_id})||
        (! exists $args{component_id} or ! defined $args{component_id})){ 
        $errmsg = "Entity::Component::Export::Nfsd3->new need a cluster_id and a component_id named argument!";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    # We create a new DBIx containing new entity
    my $self = $class->SUPER::new( %args);

    return $self;

}

sub getConf {
    my $self = shift;
    my %conf = ( );
    
    my $conf_row = $self->{_dbix}->nfsd3s->first;
    if($conf_row) {
        $conf{nfsd3_statdopts} = $conf_row->get_column('nfsd3_statdopts');
        $conf{nfsd3_need_gssd} = $conf_row->get_column('nfsd3_need_gssd');
        $conf{nfsd3_rpcnfsdcount} = $conf_row->get_column('nfsd3_rpcnfsdcount');
        $conf{nfsd3_rpcnfsdpriority} = $conf_row->get_column('nfsd3_rpcnfsdpriority');
        $conf{nfsd3_rpcmountopts} = $conf_row->get_column('nfsd3_rpcmountopts');
        $conf{nfsd3_need_svcgssd} = $conf_row->get_column('nfsd3_need_svcgssd');
        $conf{nfsd3_rpcsvcgssdopts} = $conf_row->get_column('nfsd3_rpcsvcgssdopts');
        
        my @exports = ();
        my $conf_exports = $conf_row->nfsd3_exports;
        while (my $export_row = $conf_exports->next) {
            my $client_rs = $export_row->nfsd3_exportclients;
            my @clients = ();
            while (my $client_row = $client_rs->next) {
                push @clients, {
                    nfsd3_exportclient_name => $client_row->get_column('nfsd3_exportclient_name'),
                    nfsd3_exportclient_options => $client_row->get_column('nfsd3_exportclient_options'),
                }
            }
            push @exports, { 
                nfsd3_export_path => $export_row->get_column('nfsd3_export_path'),
                clients => \@clients,
            };        
        }
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
        CLIENT:
        for my $client ( @{ $export->{clients} } ) {
            $self->createExport(device => $export->{nfsd3_export_path},
                                client_name => $client->{nfsd3_exportclient_name},
                                client_options => $client->{nfsd3_exportclient_options});
            last CLIENT; #Temporary: we can create only one client with one export
        }        
    }

#    my $self = shift;
#    my($conf) = @_;
#    
#    # delete old conf        
#    my $conf_row = $self->{_dbix}->nfsd3s->first();
#    $conf_row->delete() if (defined $conf_row); 
#
#    # create
#    $conf_row = $self->{_dbix}->nfsd3s->create( {
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
    if(! exists $args{device} or ! defined $args{device}) {
        $errmsg = "EComponent::EExport::ENfsd3->getMountDir needs a device named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    my $dir = $args{device};
    $dir =~ s/\//_/g;
    return "/nfsexports/".$dir;
}

=head2 addExport
    
    Desc : This function add new export to the db component
    args : export_id, client_name, client_options 

=cut

sub addExport {
    my $self = shift;
    my %args = @_;
    if (! exists $args{device} or ! defined $args{device}) {
        $errmsg = "Component::Export::Nfsd3->addExport needs a device named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    my $component = $self->{_dbix}->nfsd3s->first;
    my $export = $component->nfsd3_exports->create({
        nfsd3_export_path => $args{device}
    });
    return $export->get_column('nfsd3_export_id')
}

=head2 addExportClient
    
    Desc : This function a new client with options to an export.
    args : export_id, client_name, client_options 

=cut

sub addExportClient {
    my $self = shift;
    my %args = @_;

    if ((! exists $args{export_id} or ! defined $args{export_id}) ||
        (! exists $args{client_name} or ! defined $args{client_name}) ||
        (! exists $args{client_options} or ! defined $args{client_options})) {
        $errmsg = "Component::Export::Nfsd3->addExportClient needs a export_id, client_name and client_options named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    my $component = $self->{_dbix}->nfsd3s->first;
    my $exportclient_rs = $component->nfsd3_exports->single({nfsd3_export_id =>$args{export_id}})->nfsd3_exportclients;
    my $exportclient = $exportclient_rs->create({
        nfsd3_exportclient_name => $args{client_name},
        nfsd3_exportclient_options => $args{client_options}
    });
    return $exportclient->get_column('nfsd3_exportclient_id')
}

=head2 removeExport
    
    Desc : This function delete an export and all its clients
    args : export_id

=cut

sub removeExport {
    my $self = shift;
    my %args  = @_;
    if (! exists $args{nfsd3_export_id} or ! defined $args{nfsd3_export_id}) {
        $errmsg = "Component::Export::Nfsd3->removeExport needs an nfsd3_export_id named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    my $component = $self->{_dbix}->nfsd3s->first;
    return $component->nfsd3_exports->find($args{nfsd3_export_id})->delete();
}

=head2 removeExportClient
    
    Desc : This function delete a client from an export
    args : client_id

=cut

sub removeExportClient {
    my $self = shift;
    my %args  = @_;    
    if (! exists $args{client_id} or ! defined $args{client_id}) {
        $errmsg = "Component::Export::Nfsd3->removeExportClient needs a client_id named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    #return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->delete();    
}


# return a data structure to pass to the template processor for /etc/exports file
sub getTemplateDataExports {
    my $self = shift;
    my $data = {};
    my $general_config = $self->{_dbix}->nfsd3s->first;
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
    my $general_config = $self->{_dbix}->nfsd3s->first;
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
    my $general_config = $self->{_dbix}->nfsd3s->first;
    if(not $general_config) {
        # TODO throw exception then no configuration
    } 
    $data->{nfsd3_rpcnfsdcount} = $general_config->get_column('nfsd3_rpcnfsdcount');
    $data->{nfsd3_rpcnfsdpriority} = $general_config->get_column('nfsd3_rpcnfsdpriority');
    $data->{nfsd3_rpcmountopts} = $general_config->get_column('nfsd3_rpcmountopts');
    $data->{nfsd3_need_svcgssd} = $general_config->get_column('nfsd3_need_svcgssd');
    $data->{nfsd3_rpcsvcgssdopts} = $general_config->get_column('nfsd3_rpcsvcgssdopts');
    
    return $data;   
}

=head2 createExport
    
    Desc : This function enqueue a ECreateExport operation
    args : client_name, device, options
    
=cut

sub createExport {
    my $self = shift;
    my %args = @_;
    if((! exists $args{client_name} or ! defined $args{client_name})||
       (! exists $args{device} or ! defined $args{device}) ||
       (! exists $args{client_options} or ! defined $args{client_options})) {
           $errmsg = "createExport needs device, client_name and client_options named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    my $admin = Administrator->new();
    
    my %params = $self->getAttrs();
    $log->debug("New Operation CreateExport with attrs : " . %params);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateExport',
        params   => {
            component_instance_id => $self->getAttr(name=>'component_instance_id'),
            device => $args{device},
            client_name => $args{client_name},
            client_options => $args{client_options}
        },
    );
}

1;
