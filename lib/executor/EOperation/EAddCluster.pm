# EAddCluster.pm - Operation class implementing Cluster creation operation

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

EEntity::Operation::EAddMotherboard - Operation class implementing Motherboard creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Motherboard creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EAddCluster;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;

use Entity::Cluster;
use Entity::Systemimage;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 new

    my $op = EEntity::EOperation::EAddMotherboard->new();

EEntity::Operation::EAddMotherboard->new creates a new AddMotheboard operation.

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

    $op->_init() is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;

    return;
}

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
        $errmsg = "EAddCluster->prepare need an internal_cluster named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    my $adm = Administrator->new();
    my $params = $self->_getOperation()->getParams();

    $self->{_objs} = {};
    
    # Cluster instantiation
    eval {
        $self->{_objs}->{cluster} = Entity::Cluster->new(%$params);
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddCluster->prepare : cluster_id $params->{cluster_name} does not find\n" . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    $self->{econtext} = EFactory::newEContext(ip_source => "127.0.0.1", ip_destination => "127.0.0.1");

}



sub execute {
    my $self = shift;

    my $adm = Administrator->new();
    my $si_location = $self->{_objs}->{cluster}->getAttr(name =>"cluster_si_location");
    my $si_access_mode = $self->{_objs}->{cluster}->getAttr(name =>"cluster_si_access_mode");
    my $si_shared = $self->{_objs}->{cluster}->getAttr(name =>"cluster_si_shared");
    my $systemimage = Entity::Systemimage->get(id => $self->{_objs}->{cluster}->getAttr(name =>"systemimage_id"));;
    
    if($si_location eq 'diskless') {
        if(not $si_shared) {
            $systemimage->setAttr(name => 'systemimage_dedicated', value => 1);
            $systemimage->save();
        } 
    }

    # Create cluster directory
    my $command = "mkdir -p /clusters/" . $self->{_objs}->{cluster}->getAttr(name =>"cluster_name");
    $self->{econtext}->execute(command => $command);
    $log->debug("Execution : mkdir -p /clusters/" . $self->{_objs}->{cluster}->getAttr(name => "cluster_name"));

    # set initial state to down
    $self->{_objs}->{cluster}->setAttr(name => 'cluster_state', value => 'down:'.time);
    
    # Save the new cluster in db
    $self->{_objs}->{cluster}->save();

    # automatically add System|Monitoragent|Logger components
    if($systemimage) {
        my $components = $systemimage->getInstalledComponents(); 
        foreach my $comp (@$components) {
            if($comp->{component_category} =~ /(System|Monitoragent|Logger)/) {
                $self->{_objs}->{cluster}->addComponent(component_id => $comp->{component_id});
                $log->info("Component $comp->{component_name} automatically added");
            }
        }
    }
    $log->info("Cluster <".$self->{_objs}->{cluster}->getAttr(name=>"cluster_name") ."> is now added");
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