# KanopyaWorkflow.pm - Kanopya Workflow component
#    Copyright 2011 Hedera Technology SAS
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
# Created 5 june 2012


=pod
=begin classdoc

Kanopya Workflow Manager.
Specify methods only used when Kanopya is the workflow manager

=end classdoc
=cut


package Entity::Component::Kanopyaworkflow0;
use base 'Entity::Component';
use base 'Manager::WorkflowManager';

use strict;
use warnings;
use General;
use Kanopya::Exceptions;
use Entity::Host;

use Hash::Merge qw( merge);
use Log::Log4perl 'get_logger';
use WorkflowStep;
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

@constructor

Override the constructor to link the new workflow manager to the common workflow definitions.

@return the workflow manager instance

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    $self->linkCommonWorkflowsDefs();

    return $self;
}


=pod
=begin classdoc

Specify automatic values of Kanopya Workflow Manager

=end classdoc
=cut

sub _getAutomaticValues{
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['automatic_params'],
                                         optional => {service_provider_id => undef});

    my $automatic_params = $args{automatic_params};

    if (exists $automatic_params->{context}->{host}) {
        my $host = Entity::Host->find(hash => {'node.node_hostname' => $args{host_name}});
        $automatic_params->{context}->{host} = $host;
    }
    if (exists $automatic_params->{context}->{cloudmanager_comp}) {
        my $host = Entity::Host->find(hash => {'node.node_hostname' => $args{host_name}});
        my $cloudmanager_id   = $host->getAttr(name => 'host_manager_id');
        my $cloudmanager_comp = Entity->get(id => $cloudmanager_id);
        $automatic_params->{context}->{cloudmanager_comp} = $cloudmanager_comp;
    }
    if (exists $automatic_params->{context}->{cluster}) {
        my $service_provider = Entity->get(id => $args{service_provider_id});
        $automatic_params->{context}->{cluster} = $service_provider;
    }

    return $automatic_params;
}


=pod
=begin classdoc

Merges automatic and specific params

@param all_params hashref of parameters containing specific and automatic params

=end classdoc
=cut

sub _defineFinalParams{
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'all_params' ]);

    return merge($args{all_params}->{automatic}, $args{all_params}->{specific});
}

1;
