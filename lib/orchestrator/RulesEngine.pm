# RulesEngine.pm - Object class of RulesEngine

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
# Created 27 Feb. 2013

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
use base 'BaseDB';
use Message;

use strict;
use warnings;
use Data::Dumper;
use Entity::ServiceProvider;

use Log::Log4perl "get_logger";

my $log = get_logger("");

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }


=pod

=begin classdoc

@constructor

Create a new instance of the class.

@return a class instance

=end classdoc

=cut

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;

    my $conf = Kanopya::Config::get('rulesengine');

    my ($login, $password) = ($conf->{user}{name}, $conf->{user}{password});
    BaseDB->authenticate(login => $login, password => $password);

    return $self;
}


=pod

=begin classdoc

Main loop of rules engine. Collect rules managed by the ruleengine instance and evaluate them

=end classdoc

=cut

sub oneRun {
    my $self = shift;

    if (defined $self->{_time_step}) {
        $log->info("## UPDATE ALL $self->{_time_step} SECONDS##");
    }

    # Select all the rules to be evaluated
    # i.e. rules of service provider with a CollectorManager
    my $rules = $self->getRulesToEvaluate();

    $self->evalRules(rules => $rules);
}


=pod

=begin classdoc

Compute rules evaluated bu rules engine. All rules from service providers with a Collector Manager.

@return reference on an array of rules

=end classdoc

=cut

sub getRulesToEvaluate {
    my $self = shift;

    my @rules = ();

    # TODO Add rules prefetch
    my @service_providers = Entity::ServiceProvider->search(hash => {});

    SP:
    for my $service_provider (@service_providers){
        eval {
            $service_provider->getManager(manager_type => "CollectorManager");
        };
        if ($@){
            $log->info('Rules Engine skip service provider '.$service_provider->id.' because it has no collector manager');
            next SP;
        }
        push @rules, $service_provider->rules;
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

    for my $rule (@{$args{rules}}) {
        $log->info('Evaluation rule <'.($rule->id).'> <'.($rule->formula_string).'>');
        my $evaluation = $rule->evaluate();
        $rule->setEvaluation(evaluation => $evaluation);
        $rule->manageWorkflows(evaluation => $evaluation);
    }
}


=pod

=begin classdoc

Launch rules engine loop regularly

=end classdoc

=cut

sub run {
    my $self = shift;
    my $running = shift;

    Message->send(
        from    => 'RulesEngine',
        level   => 'info',
        content => "Kanopya Rules Engine started."
    );

    while ( $$running ) {
        # Load conf
        my $conf = Kanopya::Config::get('rulesengine');
        $self->{_time_step} = $conf->{time_step};

        my $start_time = time();
        $self->oneRun();

        my $update_duration = time() - $start_time;
        $log->info( "Manage duration : $update_duration seconds" );
        if ( $update_duration > $self->{_time_step} ) {
            $log->warn("Rules Engine duration > graphing time step (conf)");
        } else {
            sleep( $self->{_time_step} - $update_duration );
        }
    }

    Message->send(
        from    => 'RulesEngine',
        level   => 'warning',
        content => "Kanopya RuleEngine stopped"
    );
}
