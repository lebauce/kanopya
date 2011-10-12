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
package EEntity::ECluster;
use base "EEntity";

use Entity::Powersupplycard;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use IO::Socket;
use Net::Ping;

my $log = get_logger("executor");
my $errmsg;

=head2 new

    my comp = ECluster->new();

ECluster::new creates a new component object.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

ECluster::_init is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;

    return;
}

sub create {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ["econtext"]);

    my $si_location = $self->_getEntity()->getAttr(name =>"cluster_si_location");
    my $si_access_mode = $self->_getEntity()->getAttr(name =>"cluster_si_access_mode");
    my $si_shared = $self->_getEntity()->getAttr(name =>"cluster_si_shared");
    my $systemimage = Entity::Systemimage->get(id => $self->_getEntity()->getAttr(name =>"systemimage_id"));;
    
    if($si_location eq 'diskless') {
        if(not $si_shared) {
            $systemimage->setAttr(name => 'systemimage_dedicated', value => 1);
            $systemimage->save();
        } 
    }

    # Create cluster directory
    my $command = "mkdir -p /clusters/" . $self->_getEntity()->getAttr(name =>"cluster_name");
    $args{econtext}->execute(command => $command);
    $log->debug("Execution : mkdir -p /clusters/" . $self->_getEntity()->getAttr(name => "cluster_name"));

    # set initial state to down
    $self->_getEntity()->setAttr(name => 'cluster_state', value => 'down:'.time);
    
    # Save the new cluster in db
    $self->_getEntity()->save();

    # automatically add System|Monitoragent|Logger components
    if($systemimage) {
        my $components = $systemimage->getInstalledComponents(); 
        foreach my $comp (@$components) {
            if($comp->{component_category} =~ /(System|Monitoragent|Logger)/) {
                $self->_getEntity()->addComponent(component_id => $comp->{component_id});
                $log->info("Component $comp->{component_name} automatically added");
            }
        }
    }
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
