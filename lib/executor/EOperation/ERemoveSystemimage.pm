# ERemoveSystemimage.pm - Operation class implementing System image deletion operation

#    Copyright © 2010-2012 Hedera Technology SAS
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

EOperation::ERemoveSystemimage - Operation class implementing System image deletion operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image deletion operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package EOperation::ERemoveSystemimage;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use EFactory;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Systemimage;

our $VERSION = '1.00';
my $log = get_logger("executor");
my $errmsg;

sub checkOp{
    my $self = shift;
    my %args = @_;

    # check if systemimage is not active
    $log->debug("checking systemimage active value <" .
                $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_id') . ">");
    if($self->{_objs}->{systemimage}->getAttr(name => 'active')) {
        $errmsg = "EOperation::ERemoveSystemiamge->new : systemimage <" .
                  $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_id') .
                  "> is already active";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => \%args, required => ["internal_cluster"]);
    
    my $params = $self->_getOperation()->getParams();

    General::checkParams(args => $params, required => [ "systemimage_id" ]);

    $self->{_objs} = {};
    $self->{executor} = {};

    # Get instance of Systemimage Entity
    $log->info("Load systemimage instance");
    eval {
       $self->{_objs}->{systemimage} = Entity::Systemimage->get(id => $params->{systemimage_id});
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EActivateSystemimage->prepare : systemimage_id " .
                  "$params->{systemimage_id} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    $log->debug("get systemimage self->{_objs}->{systemimage} of type : " .
                ref($self->{_objs}->{systemimage}));

    # Check Parameters and context
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation ActivateSystemimage failed an error occured :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # Instanciate executor Cluster
    $self->{executor}->{obj} = Entity::ServiceProvider::Inside::Cluster->get(
                                   id => $args{internal_cluster}->{executor}
                               );
}

sub execute{
    my $self = shift;
    $self->SUPER::execute();

    my $container = $self->{_objs}->{systemimage}->getDevice;

    # Remove system image container.
    $log->info("Systemimage container deletion");

    # Get the disk manager of the current container
    my $edisk_manager = EFactory::newEEntity(data => $container->getDiskManager);
    my $econtext = EFactory::newEContext(
                       ip_source      => $self->{executor}->{obj}->getMasterNodeIp(),
                       ip_destination => $container->getServiceProvider->getMasterNodeIp()
                   );

    $edisk_manager->removeDisk(container => $container, econtext => $econtext);

    $self->{_objs}->{systemimage}->delete();
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
