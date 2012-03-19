# Iscsitarget1.pm -Ietd (iscsi target) 1 server component (Adminstrator side)
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
# Created 5 august 2010

=head1 NAME

<Entity::Component::Iscsitarget1> <Iscsitarget component concret class>

=head1 VERSION

This documentation refers to <Entity::Component::Iscsitarget1> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component::Iscsitarget1>;

my $component_instance_id = 2; # component instance id

Entity::Component::Iscsitarget1->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component::Iscsitarget1->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component::Iscsitarget1 is class allowing to instantiate an Mysql5 component
This Entity is empty but present methods to set configuration.

=head1 METHODS

=cut
package Entity::Component::Iscsitarget1;
use base "Entity::Component";

use strict;
use warnings;

use General;
use Administrator;
use Kanopya::Exceptions;

use Entity::Container;
use Entity::ContainerAccess::IscsiContainerAccess;

use Log::Log4perl "get_logger";
use Data::Dumper;


my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }

use constant ACCESS_MODE => {
    READ_WRITE => 'wb',
    READ_ONLY  => 'ro',
};

sub getLun{
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'iscsitarget1_lun_id', 'iscsitarget1_target_id' ]);

    my $target_row = $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id});
    my $lun_row = $target_row->iscsitarget1_luns->find($args{iscsitarget1_lun_id});
    return {
            iscsitarget1_lun_number => $lun_row->get_column('iscsitarget1_lun_number'),
            iscsitarget1_lun_device => $lun_row->get_column('iscsitarget1_lun_device'),
            iscsitarget1_lun_typeio => $lun_row->get_column('iscsitarget1_lun_typeio'),
            iscsitarget1_lun_iomode => $lun_row->get_column('iscsitarget1_lun_iomode'),
    };
}

sub getConf {
    my $self = shift;
    my %conf = ( );
    
    my $conf_rs = $self->{_dbix}->iscsitarget1_targets;
    my @targets = ();
    while (my $conf_row = $conf_rs->next) {
        my $lun_rs = $conf_row->iscsitarget1_luns;
        my @luns = ();
        while (my $lun_row = $lun_rs->next) {
            push @luns, {
                iscsitarget1_lun_number => $lun_row->get_column('iscsitarget1_lun_number'),
                iscsitarget1_lun_device => $lun_row->get_column('iscsitarget1_lun_device'),
                iscsitarget1_lun_typeio => $lun_row->get_column('iscsitarget1_lun_typeio'),
                iscsitarget1_lun_iomode => $lun_row->get_column('iscsitarget1_lun_iomode'),
            }
        }
        push @targets, {
            iscsitarget1_target_name => $conf_row->get_column('iscsitarget1_target_name'),
            iscsitarget1_target_id   => $conf_row->get_column('iscsitarget1_target_id'),
            luns => \@luns
        };
    }
    
    $conf{targets} = \@targets;
    
    return \%conf;
}

sub setConf {
    my $self = shift;
    my($conf) = @_;
    
    for my $target ( @{ $conf->{targets} } ) {
        LUN:
        for my $lun ( @{ $target->{luns} } ) {
            my @containers
                = Entity::Container->search(
                      hash => { service_provider_id => $self->getAttr(name => 'service_provider_id') }
                  );

            # Check if specified device match to a registred container.
            my $container;
            foreach my $cont (@containers) {
                my $device = $cont->getAttr(name => 'container_device');
                if ("$device" eq "$lun->{iscsitarget1_lun_device}") {
                    $container = $cont;
                    last;
                }
            }
            if (! defined $container) {
                $errmsg = "Specified device <$lun->{iscsitarget1_lun_device}> " .
                          "does not match to an existing container.";
                $log->error($errmsg);
                throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
            }

            $self->createExport(container   => $container,
                                export_name => $target->{iscsitarget1_target_name},
                                typeio      => $lun->{iscsitarget1_lun_typeio},
                                iomode      => $lun->{iscsitarget1_lun_iomode});

            # Temporary: we can create only one lun with one target
            last LUN;
        }        
    }
}

=head2 
    
    Desc : 
    args: 

    return : a system image instance

=cut
=head2 AddTarget
B<Class>   : Public
B<Desc>    : This function add a new target entry into iscsitarget configuration.
B<args>    : 
    B<iscsitarget1_target_name> : I<String> : Identify component. Refer to component identifier table
    B<mountpoint> : I<String> : Identify cluster owning the component instance
    B<mount_option> : I<String> : Identify cluster owning the component instance
B<Return>  : Int : Targetid contained by iscsitarget component instance
B<Comment>  : None
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
=cut
sub addTarget {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'iscsitarget1_target_name' ]);

    my $iscsitarget1_rs = $self->{_dbix}->iscsitarget1_targets;
    my $res = $iscsitarget1_rs->create(\%args);

    $log->info("New target <$args{iscsitarget1_target_name}> added and return " .
               $res->get_column("iscsitarget1_target_id"));

    $res->discard_changes;
    return $res->get_column("iscsitarget1_target_id");
}

=head2 AddLun
    
    Desc : This function a new lun to a target.
    args: 
        administrator : Administrator : Administrator object to instanciate all components
    return : a system image instance

=cut
sub addLun {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "iscsitarget1_lun_device", "iscsitarget1_target_id",
                                       "iscsitarget1_lun_number", "iscsitarget1_lun_typeio",
                                       "iscsitarget1_lun_iomode" ]);

    $log->debug("New Lun try to be added with iscsitarget1_target_id " .
                "$args{iscsitarget1_target_id} iscsitarget1_lun_number " .
                "$args{iscsitarget1_lun_number} iscsitarget1_lun_device " .
                "$args{iscsitarget1_lun_device}");

    my $iscsitarget1_lun_rs = $self->{_dbix}->iscsitarget1_targets->single(
                                  { iscsitarget1_target_id => $args{iscsitarget1_target_id} }
                              )->iscsitarget1_luns;

    my $res = $iscsitarget1_lun_rs->create(
                  { iscsitarget1_target_id  => $args{iscsitarget1_target_id},
                    iscsitarget1_lun_number => $args{iscsitarget1_lun_number},
                    iscsitarget1_lun_iomode => $args{iscsitarget1_lun_iomode},
                    iscsitarget1_lun_typeio => $args{iscsitarget1_lun_typeio},
                    iscsitarget1_lun_device => $args{iscsitarget1_lun_device}, }
              );

    $log->info("New Lun <$args{iscsitarget1_lun_device}> added");

    $res->discard_changes;
    return $res->get_column('iscsitarget1_lun_id');
}

sub getTargetIdLike {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "iscsitarget1_target_name" ]);

    return $self->{_dbix}->iscsitarget1_targets->search(
               { iscsitarget1_target_name => { -like => $args{iscsitarget1_target_name} } }
           )->first()->get_column('iscsitarget1_target_id');
}

sub getFullTargetName {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "lv_name" ]);

    return $self->{_dbix}->iscsitarget1_targets->search(
               { iscsitarget1_target_name => { -like => '%'.$args{lv_name} } }
           )->first()->get_column('iscsitarget1_target_name');
}

sub getLunId {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "iscsitarget1_target_id", "iscsitarget1_lun_device" ]);

    my $target_row = $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id});
    return $target_row->iscsitarget1_luns->first(
               { iscsitarget1_lun_device=> $args{iscsitarget1_lun_device} }
           )->get_column('iscsitarget1_lun_id');
}

sub removeLun {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "iscsitarget1_target_id", "iscsitarget1_lun_id" ]);

    my $target_rs = $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id});
    return $target_rs->iscsitarget1_luns->find($args{iscsitarget1_lun_id})->delete();
}

sub removeTarget{
    my $self = shift;
    my %args  = @_;    

    General::checkParams(args     => \%args,
                         required => [ "iscsitarget1_target_id" ]);

    return $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id})->delete();
}

sub getTargetName {
    my $self = shift;
    my %args  = @_;    

    General::checkParams(args     => \%args,
                         required => [ "iscsitarget1_target_id" ]);
    
    my $target_raw = $self->{_dbix}->iscsitarget1_targets->find($args{iscsitarget1_target_id});
    return $target_raw->get_column('iscsitarget1_target_name');
}

# return a data structure to pass to the template processor 
sub getTemplateData {
    my $self = shift;
    my $data = {};

    my $targets = $self->{_dbix}->iscsitarget1_targets;
    $data->{targets} = [];
    while (my $onetarget = $targets->next) {
        my $record = {};
        $record->{target_name} = $onetarget->get_column('iscsitarget1_target_name');
        $record->{luns} = [];

        my $luns = $onetarget->iscsitarget1_luns->search();
        while(my $onelun = $luns->next) {
            push @{$record->{luns}}, { 
                number => $onelun->get_column('iscsitarget1_lun_number'),
                device => $onelun->get_column('iscsitarget1_lun_device'),
                type => $onelun->get_column('iscsitarget1_lun_typeio'),
                iomode => $onelun->get_column('iscsitarget1_lun_iomode'),
            }; 
        }
        push @{$data->{targets}}, $record;
    }
     
    return $data;      
}

=head2 getNetConf
B<Class>   : Public
B<Desc>    : This method return component network configuration in a hash ref, it's indexed by port and value is the port
B<args>    : None
B<Return>  : hash ref containing network configuration with following format : {port => protocol}
B<Comment>  : None
B<throws>  : Nothing
=cut

sub getNetConf {
    return { 3260 => ['tcp'] };
}

=head2 createExport

    Desc : Implement createExport from ExportManager interface.
           This function enqueue a ECreateExport operation.
    args : export_name, device, typeio, iomode

=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container", "export_name", "typeio", "iomode" ]);

    $log->debug("New Operation CreateExport with attrs : " . %args);
    Operation->enqueue(
        priority => 200,
        type     => 'CreateExport',
        params   => {
            storage_provider_id => $self->getAttr(name => 'service_provider_id'),
            export_manager_id   => $self->getAttr(name => 'component_id'),
            container_id => $args{container}->getAttr(name => 'container_id'),
            export_name  => $args{export_name},
            typeio       => $args{typeio},
            iomode       => $args{iomode}
        },
    );
}

=head2 removeExport

    Desc : Implement createExport from ExportManager interface.
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
            container_access_id => $args{container_access}->getAttr(name => 'container_access_id'),
        },
    );
}

=head2 getContainerAcess

    Desc : Implement getContainerAccess from ExportManager interface.
           This function return the container access hash that match
           identifiers given in paramters.
    args : lun_id, target_id

=cut

sub getContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "lun_id", "target_id" ]);

    my $target_rs = $self->{_dbix}->iscsitarget1_targets->find($args{target_id});
    my $lun_rs = $target_rs->iscsitarget1_luns->find($args{lun_id});

    my $container = {
        container_access_export => $target_rs->get_column('iscsitarget1_target_name'),
        container_access_ip     => '10.0.0.1',
        container_access_port   => 3260,
    };

    return $container;
}

=head2 addContainerAccess

    Desc : Implement addContainerAccess from ExportManager interface.
           This function create a new IscsiContainerAccess into database.
    args : container, target_id, lun_id

=cut

sub addContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container", "target_id", "lun_id" ]);

    my $access = Entity::ContainerAccess::IscsiContainerAccess->new(
                     container_id      => $args{container}->getAttr(name => 'container_id'),
                     export_manager_id => $self->getAttr(name => 'iscsitarget1_id'),
                     target_id         => $args{target_id},
                     lun_id            => $args{lun_id},
                 );

    my $access_id = $access->getAttr(name => 'container_access_id');
    $log->info("Iscsitarget1 container access <$access_id> saved to database");

    return $access;
}

=head2 delContainerAccess

    Desc : Implement delContainerAccess from ExportManager interface.
           This function delete a IscsiContainerAccess from database.
    args : container_access

=cut

sub delContainerAccess {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_access" ]);

    $args{container_access}->delete();
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
