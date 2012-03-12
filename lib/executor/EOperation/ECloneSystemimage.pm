# ECloneSystemimage.pm - Operation class implementing System image cloning operation

#    Copyright © 2010-2012 Hedera Technology SAS
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

=head1 NAME

EEntity::EOperation::ECloneSystemimage - Operation class implementing System image cloning operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image cloning operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package EOperation::ECloneSystemimage;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');

use Kanopya::Exceptions;
use EFactory;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use Template;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

sub checkOp{
    my $self = shift;
    my %args = @_;

    # Check if systemimage is not active
    $log->debug("Checking source systemimage active value <" .
                $self->{_objs}->{systemimage_source}->getAttr(name => 'systemimage_id') . ">");

    if($self->{_objs}->{systemimage_source}->getAttr(name => 'active')) {
        $errmsg = "EOperation::ECloneSystemimage->checkop : systemimage <" .
                  $self->{_objs}->{systemimage_source}->getAttr(name => 'systemimage_id') .
                  "> is already active";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # Check if systemimage name does not already exist
    $log->debug("checking unicity of systemimage_name <" . $args{params}->{systemimage_name} . ">");

    my $sysimg_exists
        = Entity::Systemimage->getSystemimage(
              hash => { systemimage_name => $args{params}->{systemimage_name} }
          );

    if (defined $sysimg_exists){
        $errmsg = "Operation::ECloneSystemimage->prepare : systemimage_name " .
                  $args{params}->{systemimage_name} . " already exist";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    $self->{_objs}    = {};
    $self->{executor} = {};

    General::checkParams(args => \%args, required => ["internal_cluster"]);
    
    my $params = $self->_getOperation()->getParams();

    # Get instance of Systemimage Entity
    $log->debug("Load systemimage instance");
    eval {
       $self->{_objs}->{systemimage_source} = Entity::Systemimage->get(id => $params->{systemimage_id});
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::ECloneSystemimage->prepare : " .
                  "systemimage_id $params->{systemimage_id} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    $log->debug("Get systemimage self->{_objs}->{systemimage} of type : " . ref($self->{_objs}->{systemimage}));
    delete $params->{systemimage_id};
    $params->{distribution_id} = $self->{_objs}->{systemimage_source}->getAttr(name => 'distribution_id');

    # Check Parameters and context
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation CloneSystemimage failed an error occured :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Create new systemimage instance
    $log->debug("Create new systemimage instance");
    eval {
        $self->{_objs}->{systemimage} = Entity::Systemimage->new(%$params);
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::ECloneSystemimage->prepare : wrong param during systemimage creation\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Check if a service provider is given in parameters, use default instead.
    eval {
        General::checkParams(args => $params, required => ["service_provider_id"]);

        $self->{_objs}->{service_provider}
            = Entity::ServiceProvider->get(id => $params->{service_provider_id});
    };
    if ($@) {
        $log->info("Service provider id not defined, using default.");
        $self->{_objs}->{service_provider}
            = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{nas});
    }

    # Check if a disk manager is given in parameters, use default instead.
    my $disk_manager;
    eval {
        General::checkParams(args => $params, required => ["disk_manager_id"]);

        $disk_manager
            = $self->{_objs}->{service_provider}->getManager(id => $params->{disk_manager_id});
    };
    if ($@) {
        $log->info("Disk manager id not defined, using default.");
        $disk_manager
            = $self->{_objs}->{service_provider}->getDefaultManager(category => 'DiskManager');
    }

    # Check if disk manager has enough free space
    my $neededsize = $self->{_objs}->{systemimage_source}->getDevice->getAttr(name => 'container_size');
    my $freespace  = $disk_manager->getFreeSpace;

    $log->debug("Size needed for systemimage device : $neededsize M, freespace left : $freespace M");
    if($neededsize > $freespace) {
        $errmsg = 'EOperation::ECloneSystemimage->prepare : not enough freespace on ' .
                  'the disk manager ($freespace M left)';
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Get the disk manager for disk creation.
    $self->{_objs}->{edisk_manager} = EFactory::newEEntity(data => $disk_manager);

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{'executor'});
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                                          ip_destination => $exec_cluster->getMasterNodeIp());

    my $service_provider_ip = $self->{_objs}->{service_provider}->getMasterNodeIp();
    $self->{_objs}->{edisk_manager}->{econtext}
        = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                ip_destination => $service_provider_ip);
}

sub execute {
    my $self = shift;

    my $esystemimage = EFactory::newEEntity(data => $self->{_objs}->{systemimage});

    $esystemimage->create(src_container => $self->{_objs}->{systemimage_source}->getDevice,
                          edisk_manager => $self->{_objs}->{edisk_manager},
                          econtext      => $self->{executor}->{econtext},
                          erollback     => $self->{erollback});

    $self->{_objs}->{systemimage}->cloneComponentsInstalledFrom(
        systemimage_source_id => $self->{_objs}->{systemimage_source}->getAttr(name => 'systemimage_id')
    );

    $log->info('System image <' . $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name') . '> is cloned');
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
