# Copyright © 2011-2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

A service template is a set of policies. A cluster could be associated to
a service template, and so the cluster configuration pattern required at 
cluster creation is automatically builded from policies by merging all
policies cluster pattern fragments, and the cluster could be reconfigured
when one or more of the service template policies is updated.

@since    2012-Aug-16
@instance hash
@self     $self

=end classdoc

=cut

package Entity::ServiceTemplate;
use base 'Entity';

use strict;
use warnings;

use Entity::Policy;
use Entity::Policy::HostingPolicy;
use Entity::Policy::StoragePolicy;
use Entity::Policy::NetworkPolicy;
use Entity::Policy::BillingPolicy;
use Entity::Policy::SystemPolicy;
use Entity::Policy::ScalabilityPolicy;
use Entity::Policy::OrchestrationPolicy;

use Clone qw(clone);

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {
    service_name => {
        label        => 'Service name',
        type         => 'string',
        pattern      => '^.*$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    service_desc => {
        label        => 'Description',
        type         => 'text',
        pattern      => '^.*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    hosting_policy_id => {
        label        => 'Hosting policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    storage_policy_id => {
        label        => 'Storage policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    network_policy_id => {
        label        => 'Network policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    scalability_policy_id => {
        label        => 'Scalability policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    system_policy_id => {
        label        => 'System policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    billing_policy_id => {
        label        => 'Billing policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
    orchestration_policy_id => {
        label        => 'Orchestration policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 1,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        getServiceTemplateDef => {
            description => 'build the service definition.',
        },
    };
}

my $POLICY_TYPES = [ 'hosting', 'storage', 'network', 'scalability', 'system', 'billing', 'orchestration' ];

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


=pod

=begin classdoc

@constructor

Create a service template from a set of policy ids. Policy parameters
(see Policy.pm) could be given with policy ids, and will be considered as
addtional params of policies. When creating a service template, if additonal
parameters found for a policy, the policy is duplicated and it's pattern is
update with the additional parameters.

@return a class instance

=end classdoc

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self;

    # Firstly pop the service template attributes
    delete $args{class_type_id};
    my $attrs = {
        service_name => delete $args{service_name},
        service_desc => delete $args{service_desc},
    };

    # Then extract the policies ids
    for my $arg (grep /_policy_id/, keys %args) {
        my $policy = Entity::Policy->get(id => delete $args{$arg});

        # Remove param_preset_id from the policy JSON
        my $json = $merge->merge($policy->toJSON, $policy->getParams(noarrays => 1));
        delete $json->{param_preset_id};

        # Browse the policy definition and create a derivated policy
        # if some empty attributes has been filled.
        my $altered = 0;
        for my $attrname (keys %{ $policy->getPolicyDef->{attributes} }) {
            if (defined $args{$attrname} and "$args{$attrname}" ne "$json->{$attrname}" and
                not $policy->getPolicyDef->{attributes}->{$attrname}->{is_virtual} and
                ref($args{$attrname}) ne "ARRAY") {

                $log->debug("$policy <" . $policy->id . ">, attr <$attrname> value has been set: " . 
                            "$json->{$attrname} => $args{$attrname}.");

                $json->{$attrname} = $args{$attrname};
                $altered = 1;
            }
        };
        if ($altered) {
            $json->{policy_name} .= ' (for service "' . $attrs->{service_name} .  '")';

            my $policyclass = 'Entity::Policy::' . ucfirst($json->{policy_type}) . 'Policy';
            $policy = $policyclass->new(%$json);
        }

        $attrs->{$arg} = $policy->id;
    }
    return $class->SUPER::new(%$attrs);
}


=pod

=begin classdoc

Merge all it's policies attributes definition to build the complete hash
that could represent a cluster configuration pattern. By setting values
to all or part of the attributes as a keys/values hash allows to build the
cluster configuration pattern for service instance that come from the
service template.

@return the dynamic attributes definition.

=end classdoc

=cut

sub getServiceTemplateDef {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         optional => { 'params' => {}, 'trigger' => undef });

    my $attributes = clone($class->toJSON(model => 1));

    # Instanciate the service template if the id is defined,
    # this should occurs at the service instanciation only.
    my $servicetemplate;
    if (defined $args{params}->{service_template_id}) {
        $servicetemplate = Entity::ServiceTemplate->get(id => $args{params}->{service_template_id});
    }

    for my $policy_type (@$POLICY_TYPES) {
        my $policy_class = 'Entity::Policy::' . ucfirst($policy_type) . 'Policy';

        # For instance, set all all policy types mandatory
        $attributes->{attributes}->{$policy_type . '_policy_id'}->{is_mandatory} = 1;
        push @ { $attributes->{displayed} }, $policy_type . '_policy_id';

        # If the service template id is defined, use its policies ids.
        if (defined $servicetemplate) {
            my $policy = $servicetemplate->getAttr(name => $policy_type . '_policy');
            $args{params}->{$policy_type . '_policy_id'} = $policy->id;

            # Set the policy id non editable
            $attributes->{attributes}->{$policy_type . '_policy_id'}->{options} = [ $policy->toJSON ];
            $attributes->{attributes}->{$policy_type . '_policy_id'}->{is_editable} = 0;
        }
        else {
            # Add the policy select box for the current policy type with options
            my @policies;
            for my $policy ($policy_class->search(hash => {})) {
                push @policies, $policy->toJSON();
            }
            $attributes->{attributes}->{$policy_type . '_policy_id'}->{options} = \@policies;
            $attributes->{attributes}->{$policy_type . '_policy_id'}->{reload}  = 1;

            # If the value for the policy not defined and the policy is mandatory...
            if ($attributes->{attributes}->{$policy_type . '_policy_id'}->{is_mandatory} and
                ! defined $args{params}->{$policy_type . '_policy_id'} and scalar(@policies)) {

                # ...set the value to the first policy in options
                $args{params}->{$policy_type . '_policy_id'} = $policies[0]->{pk};
            }
        }

        # Merge the current policy attrbiutes
        my $holder;
        my $policy_attributes;
        my $policy_args = { params        => $args{params},
                            trigger       => $args{trigger},
                            set_mandatory => defined $servicetemplate ? 1 : 0 };

        # If the policy id defined, use the the instance, use the class instead
        if (defined $args{params}->{$policy_type . '_policy_id'}) {
            $attributes->{attributes}->{$policy_type . '_policy_id'}->{value}
                = $args{params}->{$policy_type . '_policy_id'};

            # Get the policy defintion from the policy instance if the id is defined
            $holder = Entity::Policy->get(id => $args{params}->{$policy_type . '_policy_id'});

            $policy_args->{set_editable} = 0;
            $policy_args->{set_params_editable} = 1;

            # If the changed attribute that trigger the call to getServiceTemplateDef is
            # the policy id, then do not forward params to getPolicyDef.
            my $params = {};
            if (defined $args{trigger} and $args{trigger} eq $policy_type . '_policy_id') {
                delete $policy_args->{params};
            }
        }
        else {
            $holder = $policy_class;
        }

        # Finaly get the attribute defintion from the policy instance
        $policy_attributes = $holder->getPolicyDef(%$policy_args);

        # Removed policy_name and policy_desc from the displayed attr list
        shift @{ $policy_attributes->{displayed} };
        shift @{ $policy_attributes->{displayed} };

        # Remove the common policy attributes
        delete $policy_attributes->{attributes}->{policy_type};
        delete $policy_attributes->{attributes}->{policy_name};
        delete $policy_attributes->{attributes}->{policy_desc};

        $attributes = $merge->merge($attributes, $policy_attributes);
    }
    return $attributes;
}


=pod

=begin classdoc

@return the service template policies instance list.

=end classdoc

=cut

sub getPolicies {
    my $self = shift;
    my %args = @_;

    my $policies = [];

    # The service template known the type of policies
    for my $policy_type (@$POLICY_TYPES) {
        # For instance do not handle orchestration policy
        if ($self->getAttr(name => $policy_type . '_policy_id')) {
            push @$policies, Entity::Policy->get(id => $self->getAttr(name => $policy_type . '_policy_id'));
        }
    }
    return $policies;
}

1;
