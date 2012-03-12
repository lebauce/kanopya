# EAddSystemimage.pm - Operation class implementing System image creation operation

#    Copyright 2010-2012 Hedera Technology SAS
#
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

EEntity::EOperation::EAddSystemimage - Operation class implementing System image creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image creation operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package EOperation::EAddSystemimage;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use EFactory;
use Kanopya::Exceptions;
use Entity::ServiceProvider;
use Entity::ServiceProvider::Inside::Cluster;
use EEntity::EContainer::ELocalContainer;
use Entity::Masterimage;
use Entity::Systemimage;
use EEntity::ESystemimage;
use Entity::Gp;

our $VERSION = '1.00';
my $log = get_logger("executor");
my $errmsg;


=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => \%args, required => ["internal_cluster"]);

    my $params = $self->_getOperation()->getParams();

    General::checkParams(args => $params, required => [ "masterimage_id" ]);

    my $masterimage_id = $params->{masterimage_id};
    delete $params->{masterimage_id};

    $self->{_objs} = {};
    $self->{executor} = {};

    # Create new systemimage instance
    $log->info("Create new systemimage instance");
    eval {
       $self->{_objs}->{systemimage} = Entity::Systemimage->new(%$params);
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddSystemimage->prepare : wrong param " .
                  "during systemimage instantiation\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    $log->debug("get systemimage self->{_objs}->{systemimage} of type : " .
                ref($self->{_objs}->{systemimage}));

    # Get master image from params
    eval {
       $self->{_objs}->{masterimage} = Entity::Masterimage->get(id => $masterimage_id);
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddSystemimage->prepare : wrong " .
                  "masterimage_id <$params->{masterimage_id}>\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Check if a service provider is given in parameters, use default instead.
    eval {
        General::checkParams(args => $params, required => [ "storage_provider_id" ]);

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

    # Get the edisk manager for disk creation.
    $self->{_objs}->{edisk_manager} = EFactory::newEEntity(data => $disk_manager);

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{'executor'});
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                                          ip_destination => $exec_cluster->getMasterNodeIp());

    my $storage_provider_ip = $self->{_objs}->{storage_provider}->getMasterNodeIp();
    $self->{_objs}->{edisk_manager}->{econtext}
        = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                ip_destination => $storage_provider_ip);

}

sub execute {
    my $self = shift;

    my $esystemimage = EFactory::newEEntity(data => $self->{_objs}->{systemimage});
    my $emaster_container = EEntity::EContainer::ELocalContainer->new(
                                path => $self->{_objs}->{masterimage}->getAttr(name => 'masterimage_file'),
                                size => $self->{_objs}->{masterimage}->getAttr(name => 'masterimage_size'),
                                # TODO: get this value from masterimage attrs.
                                filesystem => 'ext3',
                            );

    # Instance a fake econtainer for the masterimage raw file.
    $esystemimage->create(esrc_container => $emaster_container,
                          edisk_manager  => $self->{_objs}->{edisk_manager},
                          econtext       => $self->{executor}->{econtext},
                          erollback      => $self->{erollback});

    my @group = Entity::Gp->getGroups(hash => { gp_name => 'SystemImage' });
    $group[0]->appendEntity(entity => $self->{_objs}->{systemimage});

    my $components = $self->{_objs}->{masterimage}->getProvidedComponents();
    foreach my $comp (@$components) {
        if($comp->{component_category} =~ /(System|Monitoragent|Logger)/) {
            $self->{_objs}->{systemimage}->installedComponentLinkCreation(
                component_type_id => $comp->{component_type_id}
            );
        }
    }
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

Kanopya Copyright (C) 2010-2012 Hedera Technology.

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
