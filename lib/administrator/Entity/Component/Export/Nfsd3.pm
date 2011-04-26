# Nfsd3.pm -NFS server 3 server component (Adminstrator side)
# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

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
	
	# delete old conf		
	my $conf_row = $self->{_dbix}->nfsd3s->first();
	$conf_row->delete() if (defined $conf_row); 

	# create
	$conf_row = $self->{_dbix}->nfsd3s->create( {
		nfsd3_statdopts => $conf->{nfsd3_statdopts},
		nfsd3_need_gssd => $conf->{nfsd3_need_gssd},
		nfsd3_rpcnfsdcount => $conf->{nfsd3_rpcnfsdcount},
		nfsd3_rpcnfsdpriority => $conf->{nfsd3_rpcnfsdpriority},
		nfsd3_rpcmountopts => $conf->{nfsd3_rpcmountopts},
		nfsd3_need_svcgssd => $conf->{nfsd3_need_svcgssd},
		nfsd3_rpcsvcgssdopts => $conf->{nfsd3_rpcsvcgssdopts},
	} );
	
	# exports
	foreach my $export (@{ $conf->{exports} }) {
		my $export_row = $conf_row->nfsd3_exports->create({
			nfsd3_export_path => $export->{nfsd3_export_path}
		});
		# clients options														
		foreach my $client (@{ $export->{clients} }) {
			$export_row->nfsd3_exportclients->create(
			{	
				nfsd3_exportclient_name => $client->{nfsd3_exportclient_name},
				nfsd3_exportclient_options => $client->{nfsd3_exportclient_options},
			});
		}	
	} 
}

=head2 addExport
	
	Desc : This function a new export entry into nfsd configuration.
	args : nfsd3_id, export_path
	
=cut

sub addExport {
	my $self = shift;
    my %args = @_;

	if ((! exists $args{nfsd3_id} or ! defined $args{nfsd3_id}) ||
		(! exists $args{export_path} or ! defined $args{export_path})) {
		$errmsg = "Component::Export::Nfsd3->addExport needs a nfsd3_id and export_path named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	#my $iscsitarget1_rs = $self->{_dbix}->iscsitarget1_targets;
	#my $res = $iscsitarget1_rs->create(\%args);
	#$log->info("New target <$args{iscsitarget1_target_name}> added with mount point <$args{mountpoint}> and options <$args{mount_option}> and return " .$res->get_column("iscsitarget1_target_id"));
	#return $res->get_column("iscsitarget1_target_id");
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
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	#$log->debug("New Lun try to be added with iscsitarget1_target_id $args{iscsitarget1_target_id} iscsitarget1_lun_number $args{iscsitarget1_lun_number} iscsitarget1_lun_device $args{iscsitarget1_lun_device}" );
	#my $iscsitarget1_lun_rs = $self->{_dbix}->iscsitarget1_targets->single( {iscsitarget1_target_id => $args{iscsitarget1_target_id}})->iscsitarget1_luns;

	#my $res = $iscsitarget1_lun_rs->create(\%args);
	#$log->info("New Lun <$args{iscsitarget1_lun_device}> added");
	#return $res->get_column('iscsitarget1_lun_id');
}

=head2 removeExport
	
	Desc : This function delete an export and all its clients
	args : export_id

=cut

sub removeExport {
	my $self = shift;
	my %args  = @_;
	if (! exists $args{iscsitarget1_target_id} or ! defined $args{iscsitarget1_target_id}) {
		$errmsg = "Component::Export::Nfsd3->removeExport needs an export_id named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	#return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->iscsitarget1_luns->find($args{iscsitarget1_lun_id})->delete();
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
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	#return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->delete();	
}



# return a data structure to pass to the template processor 
sub getTemplateDataNfsCommon {
	my $self = shift;
	my $data = {};
#	my $targets = $self->{_dbix}->iscsitarget1_targets;
#	$data->{targets} = [];
#	while (my $onetarget = $targets->next) {
#		my $record = {};
#		$record->{target_name} = $onetarget->get_column('iscsitarget1_target_name');
#		$record->{luns} = [];
#		my $luns = $onetarget->iscsitarget1_luns->search();
#		while(my $onelun = $luns->next) {
#			push @{$record->{luns}}, { 
#				number => $onelun->get_column('iscsitarget1_lun_number'),
#				device => $onelun->get_column('iscsitarget1_lun_device'),
#				type => $onelun->get_column('iscsitarget1_lun_typeio'),
#				iomode => $onelun->get_column('iscsitarget1_lun_iomode'),
#			}; 
#		}
#		push @{$data->{targets}}, $record;
#	}
	 
	return $data;	  
}

sub getTemplateDataNfsKernelServer {

	my $self = shift;
	my $data = {};
#	my $targets = $self->{_dbix}->iscsitarget1_targets;
#	$data->{targets} = [];
#	while (my $onetarget = $targets->next) {
#		my $record = {};
#		$record->{target_name} = $onetarget->get_column('iscsitarget1_target_name');
#		$record->{luns} = [];
#		my $luns = $onetarget->iscsitarget1_luns->search();
#		while(my $onelun = $luns->next) {
#			push @{$record->{luns}}, { 
#				number => $onelun->get_column('iscsitarget1_lun_number'),
#				device => $onelun->get_column('iscsitarget1_lun_device'),
#				type => $onelun->get_column('iscsitarget1_lun_typeio'),
#				iomode => $onelun->get_column('iscsitarget1_lun_iomode'),
#			}; 
#		}
#		push @{$data->{targets}}, $record;
#	}
	 
	return $data;	  
}


1;
