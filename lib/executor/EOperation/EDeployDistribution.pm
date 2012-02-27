# EDeployDistribution.pm - Operation class implementing distribution deployment 

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
# Created 14 july 2010

=head1 NAME

EOperation::EDeployDistribution - Operation class implementing distribution deployment

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EDeployDistribution;
use base "EOperation";

use strict;
use warnings;

use Data::Dumper;
use XML::Simple;
use Kanopya::Exceptions;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Systemimage;
use Entity::Distribution;
use Entity::Gp;
use EFactory;

use Log::Log4perl "get_logger";
my $log = get_logger("executor");

my $errmsg;
our $VERSION = '1.00';


=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

    $op->_init();
    # This private method is used to define some hash in Operation

=cut

sub _init {
    my $self = shift;
    $self->{executor};
    $self->{_objs} = {};
    return;
}

sub checkOp{
    my $self = shift;
    my %args = @_;
}

=head2 prepare

    $op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => \%args, required => [ "internal_cluster" ]);
    
    # Get Operation parameters
    my $params = $self->_getOperation()->getParams();
    
    $self->{_file_path} = $params->{file_path};
    $self->{_file_path} =~ /.*\/(.*)$/;
    my $file_name = $1;
    $self->{_file_name} = $file_name; 

    # Check tarball name and retrieve component info from tarball name
    # (temporary. TODO: component def xml file) 
    if ((not defined $file_name) || $file_name !~ /distribution_([a-zA-Z]+)_([0-9\.]+)\.tar\.bz2/) {
        $errmsg = "Incorrect component tarball name";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my ($dist_name, $dist_version) = ($1, $2);
    $self->{distribution_name} = $dist_name;
    $self->{distribution_version} = $dist_version;
    
    $log->debug("Instanciate new distribution <$self->{distribution_name}> " .
                "version <$self->{distribution_version}>");
    eval {
        $self->{_objs}->{distribution} =
            Entity::Distribution->new(distribution_name    => $self->{distribution_name},
                                      distribution_version => $self->{distribution_version},
                                      distribution_desc    => "Upload by Admin on Kanopya");
    };
    if($@) {
        my $err = $@;
        $errmsg = "Distribution upload, maybe already exists \n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Check Parameters and context
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation DeployComponent failed an error occured :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Check if a service provider is given in parameters, use default instead.
    eval {
        General::checkParams(args => $params, required => ["storage_provider_id"]);

        $self->{_objs}->{storage_provider}
            = Entity::ServiceProvider->get(id => $params->{storage_provider_id});
    };
    if ($@) {
        $log->info("Service provider id not defined, using default.");
        $self->{_objs}->{storage_provider}
            = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{nas});
    }

    # Check if a disk manager is given in parameters, use default instead.
    my $disk_manager;
    eval {
        General::checkParams(args => $params, required => ["disk_manager_id"]);

        $disk_manager
            = $self->{_objs}->{storage_provider}->getManager(id => $params->{disk_manager_id});
    };
    if ($@) {
        $log->info("Disk manager id not defined, using default.");
        $disk_manager
            = $self->{_objs}->{storage_provider}->getDefaultManager(category => 'DiskManager');
    }

    # Get the disk manager for disk creation, get the export manager for copy from file.
    my $export_manager = $self->{_objs}->{storage_provider}->getDefaultManager(category => 'ExportManager');
    $self->{_objs}->{eexport_manager} = EFactory::newEEntity(data => $export_manager);
    $self->{_objs}->{edisk_manager}   = EFactory::newEEntity(data => $disk_manager);

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{'executor'});
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                                          ip_destination => $exec_cluster->getMasterNodeIp());

    my $storage_provider_ip = $self->{_objs}->{storage_provider}->getMasterNodeIp();
    $self->{_objs}->{edisk_manager}->{econtext}
        = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                ip_destination => $storage_provider_ip);
    $self->{_objs}->{eexport_manager}->{econtext}
        = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                ip_destination => $storage_provider_ip);

}

sub execute{
    my $self = shift;
    my ($cmd, $cmd_res);

    # Untar component archive on local /tmp/<tar_root>
    $log->debug("Deploy files from archive '$self->{_file_path}'");
    $cmd = "tar -jxf $self->{_file_path} -C /tmp"; 
    $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);

    # Find size of root and etc
    for my $disk_type ("etc", "root") {
        # Get the file size
        my $file = "/tmp/$disk_type"."_$self->{distribution_name}_$self->{distribution_version}.img";
        $cmd = "du -s --bytes $file | awk '{print \$1}'";

        $log->error($cmd);
        $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);

        if($cmd_res->{'stderr'}){
            $errmsg = "Error with $disk_type disk access of <$self->{distribution_name}>";
            $log->error($errmsg);
            Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
        chomp($cmd_res->{'stdout'});

        # Create a new container with the same size
        my $eexport_manager = $self->{_objs}->{eexport_manager};
        my $edisk_manager   = $self->{_objs}->{edisk_manager};

        my $disk_name = "$disk_type"."_$self->{distribution_name}_$self->{distribution_version}";
        $self->{$disk_type}
            = $edisk_manager->createDisk(name       => $disk_name,
                                         size       => $cmd_res->{'stdout'}."B",
                                         filesystem => "ext3",
                                         econtext   => $self->{_objs}->{edisk_manager}->{econtext},
                                         erollback  => $self->{erollback});

		# Temporary export this container to copy the source distribution files.
        my $container_access
            = $eexport_manager->createExport(container   => $self->{$disk_type},
                                             export_name => $disk_name,
                                             econtext    => $self->{_objs}->{eexport_manager}->{econtext},
                                             erollback   => $self->{erollback});

        # Get the corresponding EContainerAccess
        my $econtainer_access = EFactory::newEEntity(data => $container_access);

		# Mount the container on the executor.
		$econtainer_access->mount(mountpoint => "/mnt/$disk_name",
                                  econtext   => $self->{executor}->{econtext});

		# Mount source file in loop mode.
		my $mkdir_cmd = "mkdir -p /mnt/$disk_name-source";
		$self->{executor}->{econtext}->execute(command => $mkdir_cmd);

		my $mount_cmd = "mount -o loop $file /mnt/$disk_name-source";
		$self->{executor}->{econtext}->execute(command => $mount_cmd);

        # TODO: insert an erollback to umount source file

        # Copy the filesystem.
        my $copy_fs_cmd = "cp -R --preserve=all /mnt/$disk_name-source/. /mnt/$disk_name/";

        $log->debug($copy_fs_cmd);
        $cmd_res = $self->{executor}->{econtext}->execute(command => $copy_fs_cmd);

        if($cmd_res->{'stderr'}){
            $errmsg = "Error with copy of /mnt/$disk_name-source/ to /mnt/$disk_name/: $cmd_res->{'stderr'}";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }

        $self->{_objs}->{distribution}->setAttr(name  => "$disk_type"."_container_id",
                                                value => $self->{$disk_type}->getAttr(name => 'container_id'));

        # Unmount the container, and remove the temporary export.
        $econtainer_access->umount(mountpoint => "/mnt/$disk_name",
                                   econtext   => $self->{executor}->{econtext});

        # Delete the mountpoints.
		my $mount_cmd = "umount /mnt/$disk_name-source";
		$self->{executor}->{econtext}->execute(command => $mount_cmd);
        my $mkdir_cmd = "rm -R /mnt/$disk_name-source";
		$self->{executor}->{econtext}->execute(command => $mkdir_cmd);

        # Delete the file
        $cmd = "rm $file";
        $cmd_res = $self->{executor}->{econtext}->execute(command => $cmd);

        # Remove the export at last step.
        $eexport_manager->removeExport(container_access => $container_access,
                                       econtext         => $self->{_objs}->{eexport_manager}->{econtext},
                                       erollback        => $self->{erollback});

    }
    $self->{_objs}->{distribution}->save();

    my @group = Entity::Gp->getGroups(hash => {gp_name=>'Distribution'});
    $group[0]->appendEntity(entity => $self->{_objs}->{distribution});

    # Update distribution provided components list
    $self->{_objs}->{distribution}->updateProvidedComponents();
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
