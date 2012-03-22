# ECluster.pm - Abstract class of EClusters object

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

ECluster - execution class of cluster entities

=head1 SYNOPSIS



=head1 DESCRIPTION

ECluster is the execution class of cluster entities

=head1 METHODS

=cut
package EEntity::EServiceProvider::EInside::ECluster;
use base 'EEntity';

use strict;
use warnings;
use Log::Log4perl "get_logger";
use IO::Socket;
use Net::Ping;

my $log = get_logger("executor");
my $errmsg;

sub create {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ["econtext"]);

    # Create cluster directory
    my $command = "mkdir -p /clusters/" . $self->_getEntity()->getAttr(name =>"cluster_name");
    $args{econtext}->execute(command => $command);
    $log->debug("Execution : mkdir -p /clusters/" . $self->_getEntity()->getAttr(name => "cluster_name"));

    # set initial state to down
    $self->_getEntity()->setAttr(name => 'cluster_state', value => 'down:'.time);
    
    # Save the new cluster in db
    $log->debug("trying to update the new cluster previouly created");
    $self->_getEntity()->save();

    # automatically add System|Monitoragent|Logger components
    foreach my $compclass (qw/Entity::Component::Mounttable1
                              Entity::Component::Syslogng3
                              Entity::Component::Snmpd5/) {
        my $location = General::getLocFromClass(entityclass => $compclass);
        eval { require $location; };
        $log->debug("trying to add $compclass to cluster");
        my $comp = $compclass->new();
        $comp->insertDefaultConfiguration();
        $self->_getEntity()->addComponent(component => $comp);
        $log->info("$compclass automatically added");
    }
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
