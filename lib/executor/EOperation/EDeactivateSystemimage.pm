# EDeactivateSystemimage.pm - Operation class implementing systemimage deactivation operation

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

EOperation::EDeactivateSystemimage - Operation class implementing systemimage deactivation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement systemimage deactivation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EDeactivateSystemimage;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;
use Template;
use Entity::ServiceProvider::Inside::Cluster;
use General;

my $log = get_logger("executor");
my $errmsg;


=head2 new

    my $op = EOperation::EDeactivateSystemimage->new();

    # Operation::EDeactivateSystemimage->new creates a new DeactivateSystemimage operation.
    # RETURN : EOperation::EDeactivateSystemimage : Operation deactive systemimage on execution side

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->debug("Class is : $class");
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
    $self->{executor} = {};
    $self->{_objs} = {};
    return;
}

sub checkOp {
    my $self = shift;
    my %args = @_;
    my $sysimg_name = $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name');
       
    # check if systemimage is active
    if(!$self->{_objs}->{systemimage}->getAttr(name => 'active')) {
        $errmsg = "EOperation::EDeactivateSystemimage->checkOp : system image '$sysimg_name' is already deactivated";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # check if no active cluster is using this systemimage
    my @clusters = Entity::ServiceProvider::Inside::Cluster->getClusters(hash => {
        systemimage_id => $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_id'),
        active => 1,
    });
    if(scalar(@clusters)) {
        $errmsg = "EOperation::EDeactivateSystemimage->checkOp : At least one active cluster use system image '$sysimg_name'";
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

    General::checkParams(args => \%args, required => ["internal_cluster"]);

    my $params = $self->_getOperation()->getParams();

    # Get instance of Systemimage Entity
    $log->info("Load systemimage instance");
    eval {
        $self->{_objs}->{systemimage} = Entity::Systemimage->get(id => $params->{systemimage_id});
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EDeactivateSystemimage->prepare : " .
                  "systemimage_id $params->{systemimage_id} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Get instances of container accesses from systemimages root container
    $log->info("Load root container accesses");
    eval {
        $log->info("Load container accesses within eval");
        my @access_hashs = ();
        for my $container_access (@{ $self->{_objs}->{systemimage}->getDevice->getAccesses }) {
            my $eexport_manager = EFactory::newEEntity(data => $container_access->getExportManager);
            push @access_hashs, { container_access => $container_access,
                                  eexport_manager  => $eexport_manager };
        }
        $self->{_objs}->{accesses} = \@access_hashs;
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EDeactivateSystemimage->prepare : " . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Check Parameters and context
    $self->checkOp(params => $params);

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{'executor'});

    for my $access_hash (@{ $self->{_objs}->{accesses} }) {
        my $storage_provider = $access_hash->{container_access}->getServiceProvider;
        $access_hash->{eexport_manager}->{econtext}
            = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                    ip_destination => $storage_provider->getMasterNodeIp());
    }
}

sub execute {
    my $self = shift;

    # Remove all exports of the systemimage root container
    for my $access_hash (@{ $self->{_objs}->{accesses} }) {
        my $container_access = $access_hash->{container_access};
        my $eexport_manager  = $access_hash->{eexport_manager};

        $log->info('Removing export ' . $container_access);
        $eexport_manager->removeExport(container_access => $container_access,
                                       econtext         => $eexport_manager->{econtext},
                                       erollback        => $self->{erollback});
    }

    # Set system image active in db
    $self->{_objs}->{systemimage}->setAttr(name => 'active', value => 0);
    $self->{_objs}->{systemimage}->save();

    $log->info("System Image <" . $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name') . "> deactivated");
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
