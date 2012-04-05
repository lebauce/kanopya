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
use Entity;
use EFactory;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Systemimage;
use EEntity::ESystemimage;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 _checkOp

    $op->_checkOp();
    # This private method is used to verify parameters and prerequisite
=cut

sub _checkOp {
    my $self = shift;
    my %args = @_;

    # check if systemimage is not active
    if($self->{_objs}->{systemimage}->getAttr(name => 'active')) {
        $errmsg = "EOperation::EActivateSystemimage->new : systemimage <" .
                  $self->{_objs}->{systemimage}->getAttr(name => 'systemimage_id') .
                  "> is already active";
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

    General::checkParams(args => \%args, required => [ "internal_cluster" ]);

    $self->{executor} = {};
    $self->{_objs} = {};

    my $params = $self->_getOperation()->getParams();

    General::checkParams(args => $params, required => [ "systemimage_id", "export_manager_id" ]);

    # Get instance of Systemimage Entity
    eval {
       $self->{_objs}->{systemimage} = Entity::Systemimage->get(id => $params->{systemimage_id});
    };
    if($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }

    # Check Parameters and context
    eval {
        $self->_checkOp(params => $params);
    };
    if ($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }

    # Get the disk manager for disk creation, get the export manager for copy from file.
    eval {
        $self->{_objs}->{eexport_manager}
            = EFactory::newEEntity(data => Entity->get(id => $params->{export_manager_id}));
    };
    if ($@) {
        throw Kanopya::Exception::Internal::WrongValue(error => $@);
    }
    # Get contexts
    my $exec_cluster
        = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{'executor'});
    $self->{executor}->{econtext} = EFactory::newEContext(ip_source      => $exec_cluster->getMasterNodeIp(),
                                                          ip_destination => $exec_cluster->getMasterNodeIp());
}

sub execute {
    my $self = shift;

    my $esystemimage = EFactory::newEEntity(data => $self->{_objs}->{systemimage});
    $esystemimage->activate(eexport_manager => $self->{_objs}->{eexport_manager},
                            # TODO: get export manager params form ?
                            manager_params  => {},
                            econtext        => $self->{executor}->{econtext},
                            erollback       => $self->{erollback});
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
