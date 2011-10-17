# EActivateSystemimage.pm - Operation class implementing Systemimage activation operation

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
# Created 14 july 2010

=head1 NAME

EOperation::EActivateSystemimage - Operation class implementing systemimage activation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement systemimage activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EActivateSystemimage;
use base "EOperation";

use strict;
use warnings;

use Template;
use Log::Log4perl "get_logger";
use Data::Dumper;

use Kanopya::Exceptions;
use EFactory;
use Entity::Cluster;
use Entity::Systemimage;
use EEntity::ESystemimage;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


=head2 new

    my $op = EOperation::EActivateSystemimage->new();

    # Operation::EActivateSystemimage->new creates a new ActivateSystemimage operation.
    # RETURN : EOperation::EActivateSystemimage : Operation active systemimage on execution side

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
    $self->{nas} = {};
    $self->{executor} = {};
    $self->{_objs} = {};
    return;
}

=head2 _checkOp

    $op->_checkOp();
    # This private method is used to verify parameters and prerequisite
=cut

sub _checkOp {
    my $self = shift;
    my %args = @_;

    # check if systemimage is not active
       if($self->{_objs}->{systemimage}->getAttr(name => 'active')) {
            $errmsg = "EOperation::EActivateSystemimage->new : systemimage <". $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_id') ."> is already active";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}

=head2 prepare

    $op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {

    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();
    if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) {
        $errmsg = "EActivateSystemimage->prepare need an internal_cluster named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    my $params = $self->_getOperation()->getParams();

    #### Get instance of Systemimage Entity
    eval {
       $self->{_objs}->{systemimage} = Entity::Systemimage->get(id => $params->{systemimage_id});
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EActivateSystemimage->prepare : systemimage_id $params->{systemimage_id} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Check Parameters and context
    eval {
        $self->_checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation ActivateSystemimage failed an error occured :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Instanciate Clusters
    $self->{nas}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{nas});
    $self->{executor}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{executor});

    # Get Internal IP
    my $exec_ip = $self->{executor}->{obj}->getMasterNodeIp();
    my $nas_ip = $self->{nas}->{obj}->getMasterNodeIp();

    # Instanciate context
    $self->{nas}->{econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $nas_ip);

    # Instanciate Export component.
    $self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
                                                                                      version=> "1"));
}

sub execute {
    my $self = shift;

    my $esystemimage = EFactory::newEEntity(data => $self->{_objs}->{systemimage});
    $esystemimage->activate(econtext => $self->{nas}->{econtext},erollback => $self->{erollback},component_export=>$self->{_objs}->{component_export});
#    my $sysimg_dev = $self->{_objs}->{systemimage}->getDevices();
#
#    ## provide root rsa pub key to provide ssh key authentication
#    $self->_generateAuthorizedKeys();
#
#    ## Update export to allow to motherboard to boot with this systemimage
#    my $target_name = $self->{_objs}->{component_export}->generateTargetname(name => 'root_'.$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name'));
#
#    # Get etc iscsi target information
#    my $si_access_mode = $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_dedicated') ? 'wb' : 'ro';
#
#    $self->{_objs}->{component_export}->addExport(iscsitarget1_lun_number    => 0,
#                                                iscsitarget1_lun_device    => "/dev/$sysimg_dev->{root}->{vgname}/$sysimg_dev->{root}->{lvname}",
#                                                iscsitarget1_lun_typeio    => "fileio",
#                                                iscsitarget1_lun_iomode    => $si_access_mode,
#                                                iscsitarget1_target_name=>$target_name,
#                                                econtext                 => $self->{nas}->{econtext},
#                                                erollback               => $self->{erollback});
#    my $eroll_add_export = $self->{erollback}->getLastInserted();
#    # generate new configuration file
#    $self->{erollback}->insertNextErollBefore(erollback=>$eroll_add_export);
#    $self->{_objs}->{component_export}->generate(econtext   => $self->{nas}->{econtext},
#                                                 erollback  => $self->{erollback});
#
#    $log->info("System image <".$self->{_objs}->{systemimage}->getAttr(name=>"systemimage_name") ."> is now exported with target <$target_name>");
#    # set system image active in db
#    $self->{_objs}->{systemimage}->setAttr(name => 'active', value => 1);
#    $self->{_objs}->{systemimage}->save();
#    $log->info("System image <".$self->{_objs}->{systemimage}->getAttr(name=>"systemimage_name") ."> is now active");

}

# generate /root/.ssh/authorized_keys file with nas root rsa pub key

sub _generateAuthorizedKeys {
    my $self = shift;

    # mount the root systemimage device
    my $si_devices = $self->{_objs}->{systemimage}->getDevices();
    my $mount_point = "/mnt/$si_devices->{root}->{lvm2_lv_name}";
    my $mkdir_cmd = "mkdir -p $mount_point";
    $self->{nas}->{econtext}->execute(command => $mkdir_cmd);

    my $mount_cmd = "mount /dev/$si_devices->{root}->{vgname}/$si_devices->{root}->{lvname} $mount_point";
    $self->{nas}->{econtext}->execute(command => $mount_cmd);

    my $rsapubkey_cmd = "cat /root/.ssh/kanopya_rsa.pub > $mount_point/root/.ssh/authorized_keys";
    $self->{nas}->{econtext}->execute(command => $rsapubkey_cmd);

    my $sync_cmd = "sync";
    $self->{nas}->{econtext}->execute(command => $sync_cmd);
    my $umount_cmd = "umount $mount_point";
    $self->{nas}->{econtext}->execute(command => $umount_cmd);
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
