# EActivateCluster.pm - Operation class implementing Cluster activation operation

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

EOperation::EActivateCluster - Operation class implementing cluster activation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EActivateCluster;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Systemimage;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 _checkOp

    $op->_checkOp();
    # This private method is used to verify parameters and prerequisite
=cut

sub _checkOp{
    my $self = shift;
    my %args = @_;

    # check if cluster is not active
    if($self->{_objs}->{cluster}->getAttr(name => 'active')) {
            $errmsg = "EOperation::EActivateCluster->new : cluster $args{params}->{cluster_id} is already active";
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

    $self->{_objs} = {};

    # Get Operation parameters
    my $params = $self->_getOperation()->getParams();
    $self->{_objs} = {};

     # Cluster instantiation
    eval {
        $self->{_objs}->{cluster} = Entity::ServiceProvider::Inside::Cluster->get(id => $params->{cluster_id});
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EActivateCluster->prepare : cluster_id $params->{cluster_id} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    ### Check Parameters and context
    eval {
        $self->_checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
        $errmsg = "Operation ActivateCluster failed an error occured :\n$error";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    # set cluster active in db
    $self->{_objs}->{cluster}->setAttr(name => 'active', value => 1);
    $self->{_objs}->{cluster}->save();
    $log->info("Cluster <".$self->{_objs}->{cluster}->getAttr(name=>"cluster_name") ."> is now active");

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
