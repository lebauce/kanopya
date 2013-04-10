#    Copyright © 2011 Hedera Technology SAS
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

=pod

=begin classdoc

Rules engine of Kanopya. During a run, the rules engine will evaluate all rules and manage
workflow triggering.

@since    2013-Feb-01
@instance hash
@self     $self

=end classdoc

=cut

package RulesEngine;
use base Daemon;

use strict;
use warnings;

use Message;
use Entity::ServiceProvider;

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Load rulesengine configuration and do the BaseDB authentication.

@constructor

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, optional => { 'service_providers' => [] });

    my $self = $class->SUPER::new(confkey => 'rulesengine');

    $self->{service_providers} = [];
    for my $service_provider_id (@{ $args{service_providers} }) {
        push @{ $self->{service_providers} }, Entity::ServiceProvider->get(id => $service_provider_id);
    }

    return $self;
}


=pod

=begin classdoc

Main loop of rules engine. Collect rules managed by the ruleengine instance and evaluate them

=end classdoc

=cut
sub oneRun {
    my ($self) = @_;

    # Get the start time
    my $start_time = time();

    # Select all the rules to be evaluated
    # i.e. rules of service provider with a CollectorManager
    $self->evalRules(rules => $self->getRulesToEvaluate());

    # Get the end time
    my $update_duration = time() - $start_time;
    $log->info("Manage duration : $update_duration seconds");

    if ($update_duration > $self->{config}->{time_step}) {
        $log->warn("RulesEngine duration > ruleengine time step ($self->{config}->{time_step})");
    }
    else {
        sleep($self->{config}->{time_step} - $update_duration);
    }
}


=pod

=begin classdoc

Compute rules evaluated by rules engine. All rules from service providers with a Collector Manager.

@return reference on an array of rules

=end classdoc

=cut

sub getRulesToEvaluate {
    my $self = shift;

    my @rules = ();

    my @service_providers;
    if (scalar @{ $self->{service_providers} }) {
        @service_providers = @{ $self->{service_providers} };
    }
    else {
        @service_providers = Entity::ServiceProvider->search(hash => {
                                 service_provider_type_id => { not => undef }
                             });
    }

    SP:
    for my $service_provider (@service_providers){
        eval {
            $service_provider->getManager(manager_type => "CollectorManager");
        };
        if ($@){
            $log->info('Rules Engine skip service provider '.$service_provider->id.' because it has no collector manager');
            next SP;
        }
        $log->info('RulesEngine handle rules for service provider '.  $service_provider->id);
        for my $rule ($service_provider->rules) {
            if ($rule->isActive) {
                push @rules, $rule;
            }
        }
    }
    return \@rules;
}


=pod

=begin classdoc

Call the evaluation and the triggered workflow management of all the input rules

=end classdoc

=cut

sub evalRules {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'rules' ]);

    my $memoization= {};
    for my $rule (@{$args{rules}}) {
        $log->info('Evaluation rule <'.($rule->id).'> <'.($rule->formula_string).'>');
        my $evaluation = $rule->evaluate(memoization => $memoization);
        $rule->setEvaluation(evaluation => $evaluation, memoization => $memoization);
        $rule->manageWorkflows(evaluation => $evaluation, memoization => $memoization);
    }
}
