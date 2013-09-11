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
        specialized  => 'HostingPolicy'
    },
    storage_policy_id => {
        label        => 'Storage policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_editable  => 1,
        specialized  => 'StoragePolicy'
    },
    network_policy_id => {
        label        => 'Network policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_editable  => 1,
        specialized  => 'NetworkPolicy'
    },
    scalability_policy_id => {
        label        => 'Scalability policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_editable  => 1,
        specialized  => 'ScalabilityPolicy'
    },
    system_policy_id => {
        label        => 'System policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_editable  => 1,
        specialized  => 'SystemPolicy'
    },
    billing_policy_id => {
        label        => 'Billing policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_editable  => 1,
        specialized  => 'BillingPolicy'
    },
    orchestration_policy_id => {
        label        => 'Orchestration policy',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_editable  => 1,
        specialized  => 'OrchestrationPolicy'
    },
};

sub getAttrDef { return ATTR_DEF; }


my $POLICY_TYPES = [ 'hosting', 'storage', 'network', 'scalability', 'system', 'billing', 'orchestration' ];

my $merge = Hash::Merge->new('LEFT_PRECEDENT');


=pod
=begin classdoc

@constructor

Create a service template from a set of policy ids.

@return a class instance

=end classdoc
=cut

sub new {
    my $class = shift;
    my %args = @_;

    delete $args{class_type_id};

    my $attrs = $class->processAlteredPolicies(%args);
    $attrs->{service_name} = $args{service_name};
    $attrs->{service_desc} = $args{service_desc};

    return $class->SUPER::new(%$attrs);
}


=pod
=begin classdoc

Update a service template from a set of policy ids.

@return the updated instance

=end classdoc
=cut

sub update {
    my $self = shift;
    my %args = @_;

    my $attrs = $self->processAlteredPolicies(%args);
    $attrs->{service_name} = $args{service_name};
    $attrs->{service_desc} = $args{service_desc};

    return $self->SUPER::update(%$attrs);
}


=pod
=begin classdoc

Policy parameters (see Policy.pm) could be given with policy ids, and will be considered as
addtional params of policies. When creating a service template, if additonal
parameters found for a policy, the policy is duplicated and it's pattern is
update with the additional parameters.

=end classdoc
=cut

sub processAlteredPolicies {
    my $self = shift;
    my %args = @_;

    # Browse policies and check if altered
    my $attrs = {};
    for my $policy_id (grep /_policy_id/, keys %args) {
        my $policy = Entity::Policy->get(id => delete $args{$policy_id});
        my $policyclass = ref($policy);

        # Remove param_preset_id from the policy JSON
        my $json = $policy->toJSON();
        delete $json->{param_preset_id};

        # Browse the policy definition and create a derivated policy
        # if some empty attributes has been filled.
        my $altered = 0;
        my $policyattrs = $policyclass->toJSON(params => $json)->{attributes};
        for my $attrname (keys %{ $policyattrs }) {
            if (defined $args{$attrname} && "$args{$attrname}" ne "$json->{$attrname}" &&
                ! $policyattrs->{$attrname}->{is_virtual} && ref($args{$attrname}) ne "ARRAY" &&
                ! exists $policyclass->getPolicySelectorAttrDef->{$attrname}) {

                $log->debug("$policy <" . $policy->id . ">, attr <$attrname> value has been set: " . 
                            "$json->{$attrname} => $args{$attrname}.");

                $json->{$attrname} = $args{$attrname};
                $altered = 1;
            }
        };
        if ($altered) {
            $json->{policy_name} .= ' (for service "' . $args{service_name} .  '")';

            my $policyclass = 'Entity::Policy::' . ucfirst($json->{policy_type}) . 'Policy';
            $policy = $policyclass->new(%$json);
        }
        $attrs->{$policy_id} = $policy->id;
    }
    return $attrs;
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

sub toJSON {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         optional => { 'params' => {}, 'trigger' => undef });

    # If called n an instace, return the object JSON
    if (ref($self)) {
        return $self->SUPER::toJSON();
    }

    my $attributes = clone($class->SUPER::toJSON());

    # Instanciate the service template if the id is defined,
    # this should occurs at the service instanciation only.
    my @policies;
    my $servicetemplate;
    if (defined $args{params}->{service_template_id}) {
        $servicetemplate = Entity::ServiceTemplate->get(id => $args{params}->{service_template_id});
        # Use the service template policies as options
        @policies = $servicetemplate->getPolicies();
        if (defined $args{trigger} && $args{trigger} eq 'service_template_id') {
            $args{params} = { service_template_id => $args{params}->{service_template_id} };
        }
    }
    else {
        # Use all policies as options
        @policies = Entity::Policy->search();
    }

    for my $policy_type (@$POLICY_TYPES) {
        my $policy_class = 'Entity::Policy::' . ucfirst($policy_type) . 'Policy';

        # For instance, set all all policy types mandatory
        $attributes->{attributes}->{$policy_type . '_policy_id'}->{is_mandatory} = 1;
        push @ { $attributes->{displayed} }, $policy_type . '_policy_id';

        # Build the list of json options from all policies of this type
        my @oftype  = grep { $_->policy_type eq $policy_type } @policies;
        my @options = map { { pk => $_->id, label => $_->policy_name } } @oftype;

        # And fill the options for this attribute
        $attributes->{attributes}->{$policy_type . '_policy_id'}->{options} = \@options;

        # If the service template defined in params, set the policy id non editable
        if (defined $servicetemplate) {
            $attributes->{attributes}->{$policy_type . '_policy_id'}->{is_editable} = 0;
            $args{params}->{$policy_type . '_policy_id'} = $options[0]->{pk};
        }
        else {
            $attributes->{attributes}->{$policy_type . '_policy_id'}->{reload}  = 1;
        }

        # If the value for the policy not defined and the policy is mandatory...
        if ($attributes->{attributes}->{$policy_type . '_policy_id'}->{is_mandatory} and
            ! defined $args{params}->{$policy_type . '_policy_id'} and scalar(@options)) {

            # ...set the value to the first policy in options
            $args{params}->{$policy_type . '_policy_id'} = $options[0]->{pk};
        }

        # Then merge the current policy attributes
        my $policy_attributes;
        my $policy_args = { params        => $args{params},
                            trigger       => $args{trigger},
                            set_mandatory => defined $servicetemplate ? 1 : 0 };

        # Add the policy attributes
        if (defined $args{params}->{$policy_type . '_policy_id'}) {
            $attributes->{attributes}->{$policy_type . '_policy_id'}->{value}
                = $args{params}->{$policy_type . '_policy_id'};

            # If the changed attribute that triggered the call to toJSON is
            # the policy id, then do not forward params to getPolicyDef.
            if (defined $args{trigger} and $args{trigger} eq $policy_type . '_policy_id') {
                $policy_args->{params} = {
                    $policy_type . '_policy_id' => $args{params}->{$policy_type . '_policy_id'}
                };
            }
        }

        # Finaly get the attribute definition from the policy instance
        $policy_attributes = $policy_class->toJSON(%$policy_args);

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

    # The service template known the type of policies
    my @policies;
    for my $policy_type (@$POLICY_TYPES) {
        my $policy = $self->getAttr(name => $policy_type . '_policy', deep => 1);
        if (defined $policy) {
            push @policies, $policy;
        }
    }
    return @policies;
}

1;
