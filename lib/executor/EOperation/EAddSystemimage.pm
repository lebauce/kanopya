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

    my $masterimage_id   = General::checkParam(args => $params, name => 'masterimage_id');
    my $systemimage_name = General::checkParam(args => $params, name => 'systemimage_name');
    my $systemimage_desc = General::checkParam(args => $params, name => 'systemimage_desc');

    $self->{_objs} = {};
    $self->{executor} = {};

    # Create new systemimage instance
    $log->info("Create new systemimage instance");
    eval {
       $self->{_objs}->{systemimage} = Entity::Systemimage->new(
            systemimage_name      => $systemimage_name,
            systemimage_desc      => $systemimage_desc,
       );
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
    my $storage_provider_id = General::checkParam(
                                  args    => $params,
                                  name    => 'storage_provider_id',
                                  default => $args{internal_cluster}->{nas}
                              );

    $self->{_objs}->{storage_provider} = Entity::ServiceProvider->get(id => $storage_provider_id);

    # Check if a disk manager is given in parameters, use default instead.
    my $disk_manager_id = General::checkParam(
                              args    => $params,
                              name    => 'disk_manager_id',
                              default => 0
                          );
    my $disk_manager;
    if ($disk_manager_id) {
        $disk_manager = $self->{_objs}->{storage_provider}->getManager(id => $disk_manager_id);
    }
    else {
        $disk_manager = $self->{_objs}->{storage_provider}->getDefaultManager(
                            category => 'DiskManager'
                        )
    }

    # Get the edisk manager for disk creation.
    $self->{_objs}->{edisk_manager} = EFactory::newEEntity(data => $disk_manager);

    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{executor});
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                                          ip_destination => $exec_cluster->getMasterNodeIp());

    $self->{params} = $params;
}

sub execute {
    my $self = shift;

    my $esystemimage = EFactory::newEEntity(data => $self->{_objs}->{systemimage});
    $esystemimage->createFromMasterimage(
        masterimage    => $self->{_objs}->{masterimage},
        edisk_manager  => $self->{_objs}->{edisk_manager},
        manager_params => $self->{params},
        econtext       => $self->{executor}->{econtext},
        erollback      => $self->{erollback},
    );
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
