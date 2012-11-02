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

=head2 new

B<Class>   : Public
B<Desc>    : This method allows to create a new instance of component entity.
          This is an abstract class, DO NOT instantiate it.
B<args>    : 
    B<component_id> : I<Int> : Identify component. Refer to component identifier table
    B<cluster_id> : I<int> : Identify cluster owning the component instance
B<Return>  : a new Entity::Component from parameters.
B<Comment>  : 
To save data in DB call save() on returned obj (after modification)
Like all component, instantiate it creates a new empty component instance.
You have to populate it with dedicated methods.
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
    
=cut

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
    }
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        getConf   => {
            description => 'get configuration',
            perm_holder => 'entity',
        },
        setConf   => {
            description => 'set configuration',
            perm_holder => 'entity',
        },
        # TODO(methods): Remove this method from the api once the policy ui has been reviewed
        getPolicyParams => {
            description => 'get the parameters required for policies definition.',
            perm_holder => 'entity',
        },
    }
};

sub new {
    my $class = shift;
    my %args = @_;

    # avoid abstract Entity::Component instanciation
    if ($class !~ /Entity::Component.*::(\D+)(\d*)/) {
        $errmsg = "Entity::Component->new : Entity::Component must not " .
                  "be instanciated without a concret component class";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $component_name    = $1;
    my $component_version = $2;

    # set base configuration if not passed to this constructor
    my $config = (%args) ? \%args : $class->getBaseConfiguration();
    my $template_id = undef;
    if (exists $args{component_template_id} and defined $args{component_template_id}) {
        $template_id = $args{component_template_id};
    }

    # we set the corresponding component_type
    my $hash = { component_name => $component_name };
    if (defined ($component_version) && $component_version) {
        $hash->{component_version} = $component_version;
    }

    my $self = $class->SUPER::new(component_type_id => ComponentType->find(hash => $hash)->id,
                                  %$config);

    bless $self, $class;
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

=head2 getGenericMasterGroupName

    Get an alternative group name if the correponding group 
    of the concrete class of the entity do not exists.

=cut

sub getGenericMasterGroupName {
    my $self = shift;
    return 'Component';
}

=head2 getPolicyParams

=cut

sub getPolicyParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'policy_type' ]);

    return [];
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

# Method to override to insert in db component default configuration
sub getBaseConfiguration { return {}; }
sub insertDefaultConfiguration {}
sub getClusterizationType {}
sub getExecToTest {}
sub getNetConf {}
sub needBridge { return 0; }
sub getHostsEntries { return; }
sub getPuppetDefinition { return ""; }
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

=item Entity module which is its mother class implementing global entity method

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
