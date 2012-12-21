# Component.pm - This module is components generalization
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
# Created 3 july 2010

package Entity::Component;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Data::Dumper;
use Administrator;
use General;
use ComponentType;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    service_provider_id => {
        pattern        => '^\d*$',
        is_mandatory   => 0,
        is_extended    => 0,
        is_editable    => 0
    },
    component_type_id => {
        pattern        => '^\d*$',
        is_mandatory   => 1,
        is_extended    => 0,
        is_editable    => 0
    },
    component_template_id => {
        pattern        => '^\d*$',
        is_mandatory   => 0,
        is_extended    => 0,
        is_editable    => 0
    },
    priority => {
        is_virtual => 1
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        getConf   => {
            description => 'get configuration',
        },
        setConf   => {
            description => 'set configuration',
        },
    }
};

sub new {
    my $class = shift;
    my %args = @_;

    # Avoid abstract Entity::Component instanciation
    if ($class !~ /Entity::Component.*::(\D+)(\d*)/) {
        $errmsg = "Entity::Component->new : Entity::Component must not " .
                  "be instanciated without a concret component class";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $component_name    = $1;
    my $component_version = $2;

    # Set base configuration if not passed to this constructor
    my $config = (%args) ? \%args : $class->getBaseConfiguration();
    my $template_id = undef;
    if (exists $args{component_template_id} and defined $args{component_template_id}) {
        $template_id = $args{component_template_id};
    }

    # We set the corresponding component_type
    my $hash = { component_name => $component_name };
    if (defined ($component_version) && $component_version) {
        $hash->{component_version} = $component_version;
    }

    my $self = $class->SUPER::new(component_type_id => ComponentType->find(hash => $hash)->id,
                                  %$config);

    bless $self, $class;

    # Add the component to the Component group
    Entity::Component->getMasterGroup->appendEntity(entity => $self);

    return $self;
}

=head2 getConf

    Generic method for getting simple component configuration

=cut

sub getConf {
    my $self = shift;
    my $conf = {};

    return $self->toJSON(raw => 1);
}

=head2 setConf

    Generic method for setting simple component configuration.
    If a value differs from db contents, the attr is set, and
    the object saved.

=cut

sub setConf {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['conf']);

    my $current_conf = $self->getConf;

    my $updated = 0;
    for my $attr (keys %{$args{conf}}) {
        if ($current_conf->{$attr} ne $args{conf}->{$attr}) {
            $self->setAttr(name => $attr, value => $args{conf}->{$attr});
            $updated = 1;
        }
    }
    if ($updated) {
        $self->save();
    }
}

=head2 getTemplateDirectory

B<Class>   : Public
B<Desc>    : This method return this component instance Template dir from database.
B<args>    : None
B<Return>  : String : component instance template directory
B<Comment>  : None
B<throws>  : None

=cut

sub getTemplateDirectory {
    my $self = shift;
    my $template_id = $self->getAttr(name => 'component_template_id'); 

    if (defined $template_id) {
        return $self->{_dbix}->parent->component_template->get_column('component_template_directory');
    }
}

=head2 getServiceProvider

    Desc: Returns the service provider the component is on

=cut

sub getServiceProvider {
    my $self = shift;

    return Entity->get(id => $self->getAttr(name => "service_provider_id"));
}

=head2 remove

    Desc: Overrided to remove associated service_provider_manager
          Managers can't be cascade deleted because they are linked either to a a connector or a component.

    TODO : merge connector and component or make them inerit from a parent class

=cut

sub remove {
    my $self = shift;

    my @managers = ServiceProviderManager->search( hash => {manager_id => $self->id} );
    for my $manager (@managers) {
        $manager->delete();
    }

    $self->delete();
}

=head2 toString

B<Class>   : Public
B<Desc>    : This method return a string describing the component
B<args>    : None
B<Return>  : String : Format : 'Component name' 'Component version'
B<Comment>  : None
B<throws>  : None

=cut

sub toString {
    my $self = shift;

    my $component_name = $self->{_dbix}->parent->component_type->get_column('component_name');
    my $component_version = $self->{_dbix}->parent->component_type->get_column('component_version');

    return $component_name . " " . $component_version;
}

sub supportHotConfiguration {
    return 0;
}

sub priority {
    return 50;
}

sub readyNodeAddition { return 1; }

sub readyNodeRemoving { return 1; }

=pod

=begin classdoc

=head2 getBaseConfiguration

Method to be overrided to get component basic configuration

@return %base_configuration

=end classdoc

=cut

sub getBaseConfiguration { return {}; }

=pod

=begin classdoc

=head2 insertDefaultExtendedConfiguration

Method to be overrided to insert in db default configuration for tables linked to component

=end classdoc

=cut

sub insertDefaultExtendedConfiguration {}

sub getClusterizationType {}

sub getExecToTest {}

sub getNetConf {}

sub needBridge { return 0; }

sub getHostsEntries { return; }

sub getPuppetDefinition { return ""; }


1;
