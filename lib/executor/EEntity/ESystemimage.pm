# ESystemimage.pm - Abstract class of ESystemimages object

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

ESystemimage - execution class of systemimage entities

=head1 SYNOPSIS



=head1 DESCRIPTION

ESystemimage is the execution class of systemimage entities

=head1 METHODS

=cut
package EEntity::ESystemimage;
use base "EEntity";

use strict;
use warnings;
use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

=head2 new

    my comp = ESystemimage->new();

ESystemimage::new creates a new component object.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

ESystemimage::_init is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;

    return;
}
# Params :
#  econtext : nas econtext
# devs : definition of the 2 devices
sub create {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ["econtext", "devs","component_storage", "erollback"]);

    my $adm = Administrator->new();

    my $etc_name = 'etc_'.$self->_getEntity()->getAttr(name => 'systemimage_name');
    my $root_name = 'root_'.$self->_getEntity()->getAttr(name => 'systemimage_name');

    # creation of etc and root devices based on distribution devices
    $log->info('etc device creation for new systemimage');
    my $etc_id = $args{component_storage}->createDisk(name           => $etc_name,
                                                      size           => $args{devs}->{etc}->{lvsize}."B",
                                                      filesystem     => $args{devs}->{etc}->{filesystem},
                                                      econtext       => $args{econtext},
                                                      erollback     => $args{erollback});

    $log->info('etc device creation for new systemimage');
    my $root_id = $args{component_storage}->createDisk(name          => $root_name,
                                                       size          => $args{devs}->{root}->{lvsize}."B",
                                                       filesystem    => $args{devs}->{root}->{filesystem},
                                                       econtext      => $args{econtext},
                                                       erollback     => $args{erollback});

    # copy of distribution data to systemimage devices
    $log->info('etc device fill with distribution data for new systemimage');
    my $command = "dd if=/dev/$args{devs}->{etc}->{vgname}/$args{devs}->{etc}->{lvname} of=/dev/$args{devs}->{etc}->{vgname}/$etc_name bs=1M";
    my $result = $args{econtext}->execute(command => $command);
    # TODO dd command execution result checking

    $log->info('root device fill with distribution data for new systemimage');
    $command = "dd if=/dev/$args{devs}->{root}->{vgname}/$args{devs}->{root}->{lvname} of=/dev/$args{devs}->{root}->{vgname}/$root_name bs=1M";
    $result = $args{econtext}->execute(command => $command);
    # TODO dd command execution result checking

    $self->_getEntity()->setAttr(name => "etc_device_id", value => $etc_id);
    $self->_getEntity()->setAttr(name => "root_device_id", value => $root_id);
    $self->_getEntity()->setAttr(name => "active", value => 0);

    $self->_getEntity()->save();
    $log->info('System image <'.$self->_getEntity()->getAttr(name => 'systemimage_name') .'> is added');

    return $self->_getEntity()->getAttr(name => "systemimage_id");
}

sub generateAuthorizedKeys{
    my $self = shift;

    my %args = @_;

    General::checkParams(args => \%args, required => ["econtext"]);
    # mount the root systemimage device
    my $si_devices = $self->_getEntity()->getDevices();
    
    my $mount_point = "/mnt/$si_devices->{root}->{lvm2_lv_name}";
    my $mkdir_cmd = "mkdir -p $mount_point";
    $args{econtext}->execute(command => $mkdir_cmd);

    my $mount_cmd = "mount /dev/$si_devices->{root}->{vgname}/$si_devices->{root}->{lvname} $mount_point";
    $args{econtext}->execute(command => $mount_cmd);

    my $rsapubkey_cmd = "cat /root/.ssh/kanopya_rsa.pub > $mount_point/root/.ssh/authorized_keys";
    $args{econtext}->execute(command => $rsapubkey_cmd);

    my $sync_cmd = "sync";
    $args{econtext}->execute(command => $sync_cmd);
    my $umount_cmd = "umount $mount_point";
    $args{econtext}->execute(command => $umount_cmd);
}

sub activate {
    my $self = shift;

    my %args = @_;

    General::checkParams(args => \%args, required => ["econtext" , "component_export", "erollback"]);
    
     my $sysimg_dev = $self->_getEntity()->getDevices();

    ## provide root rsa pub key to provide ssh key authentication
    $self->generateAuthorizedKeys(econtext=>$args{econtext});

    ## Update export to allow to host to boot with this systemimage
    my $target_name = $args{component_export}->generateTargetname(name => 'root_'.$self->_getEntity()->getAttr(name => 'systemimage_name'));

    # Get etc iscsi target information
    my $si_access_mode = $self->_getEntity()->getAttr(name => 'systemimage_dedicated') ? 'wb' : 'ro';

    $args{component_export}->addExport(iscsitarget1_lun_number    => 0,
                                                iscsitarget1_lun_device    => "/dev/$sysimg_dev->{root}->{vgname}/$sysimg_dev->{root}->{lvname}",
                                                iscsitarget1_lun_typeio    => "fileio",
                                                iscsitarget1_lun_iomode    => $si_access_mode,
                                                iscsitarget1_target_name   =>$target_name,
                                                econtext                   => $args{econtext},
                                                erollback                  => $args{erollback});
    my $eroll_add_export = $args{erollback}->getLastInserted();
    # generate new configuration file
    $args{erollback}->insertNextErollBefore(erollback=>$eroll_add_export);
    $args{component_export}->generate(econtext   => $args{econtext},
                                      erollback  => $args{erollback});

    $log->info("System image <".$self->_getEntity()->getAttr(name=>"systemimage_name") ."> is now exported with target <$target_name>");
    # set system image active in db
    $self->_getEntity()->setAttr(name => 'active', value => 1);
    $self->_getEntity()->save();
    $log->info("System image <".$self->_getEntity()->getAttr(name=>"systemimage_name") ."> is now active");
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
