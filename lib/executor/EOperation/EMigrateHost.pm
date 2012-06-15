# EMigrateHost.pm - Operation class implementing component installation on systemimage

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
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

EOperation::EMigrateHost - Operation class implementing component installation on systemimage

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EMigrateHost;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::ServiceProvider;
use Entity::Host;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


=head2 prepare

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    General::checkParams(args => $self->{context}, required => [ "host", "vm", "cloudmanager_comp" ]);

    eval {
        # Check cloudCluster
        if( not defined $self->{context}->{cluster}){
            $self->{context}->{cluster} = Entity::ServiceProvider->get(
                                                     id => $self->{context}->{host}->getClusterId()
                                                 );
        }
        #TODO Check if a cloudmanager is in the cluster
        # Get OpenNebula Cluster (now fix but will be configurable)

        # Check if host is on the hypervisors cluster
        if ($self->{context}->{'host'}->getClusterId() !=
            $self->{context}->{'vm'}->getServiceProvider->getAttr(name => "entity_id")) {
            throw Kanopya::Exception::Internal::WrongValue(error => "vm is not on the hypervisor cluster");
        }

        #Check if there is enough ressource in destination host

        my $vm_id      = $self->{context}->{vm}->getAttr(name => 'entity_id');
        my $cluster_id = $self->{context}->{vm}->getClusterId();
        my $hv_id      = $self->{context}->{'host'}->getId();

        my $cm    = CapacityManagement->new(cluster_id => $cluster_id);
        my $check = $cm->isMigrationAuthorized(vm_id => $vm_id, hv_id => $hv_id);

        if($check == 0){
            my $errmsg = "Not enough ressource in HV $hv_id for VM $vm_id migration";
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
    };
    if($@) {
        my $err = $@;
        $errmsg = "Incorrect params dst<" . $self->{context}->{host}->getAttr(name => 'entity_id') .
                  ">, host <" . $self->{context}->{vm}->getAttr(name => 'entity_id') . "\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}

sub execute{
    my $self = shift;

    $self->{context}->{cloudmanager_comp}->migrateHost( host               => $self->{context}->{vm},
                                                        hypervisor_dst     => $self->{context}->{host},
                                                        hypervisor_cluster => $self->{context}->{cluster});

    $log->info("VM <" . $self->{context}->{vm}->getAttr(name => 'entity_id') . "> is migrating to <" .
               $self->{context}->{host}->getAttr(name => 'entity_id') . ">");
}

sub finish{
  my $self = shift;

  delete $self->{context}->{vm};
  delete $self->{context}->{host};
}


sub postrequisites {
    my $self = shift;
    my $is_check = $self->{context}->{cloudmanager_comp}->checkMigration(
        host               => $self->{context}->{vm},
        hypervisor_dst     => $self->{context}->{host},
        hypervisor_cluster => $self->{context}->{cluster},
    );

    ($is_check == 1)? return 0 : return 15;
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
