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
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
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
	cluster_id        =>  { pattern        => '^\d*$',
                            is_mandatory   => 0,
                            is_extended    => 0,
                            is_editable    => 0
                          },
    component_type_id => { pattern        => '^\d*$',
                           is_mandatory   => 1,
                           is_extended    => 0,
                           is_editable    => 0
                         },
    tier_id           => { pattern        => '^\d*$',
                           is_mandatory   => 0,
                           is_extended    => 0,
                           is_editable    => 0
                         },
    component_template_id => { pattern        => '^\d*$',
                               is_mandatory   => 0,
                               is_extended    => 0,
                               is_editable    => 0
                             },
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my $class = shift;
    my %args = @_;

	# avoid abstract Entity::Component instanciation
	if($class !~ /Entity::Component::(.+)(\d+)/) {
		$errmsg = "Entity::Component->new : Entity::Component must not be instanciated without a concret component class";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
	}
	my $component_name    = $1;
	my $component_version = $2;

	# set base configuration if not passed to this constructor
	my $config;
	if(not %args) {
		$config = $class->getBaseConfiguration();
	} else {
		$config = \%args;
	}

	
	
    my $template_id = undef;
    if(exists $args{component_template_id} and defined $args{component_template_id}) {
        $template_id = $args{component_template_id};
    }

	# we set the corresponding component_type
	my $admin = Administrator->new();
	my $component_type_id = $admin->{db}->resultset('ComponentType')->search(
		{ component_name    => $component_name,
		  component_version => $component_version
		}
	)->single->id;
		               
	$config->{component_type_id} = $component_type_id;
	
		
#~ 
    #~ # Check if component_template_id correspond to component_id
    #~ if(defined $template_id) {
        #~ my $row = $admin->{db}->resultset('ComponentTemplate')->find($template_id);
        #~ if(not defined $row) {
            #~ $errmsg = "Entity::Component->new : component_template_id does not exist";
            #~ $log->error($errmsg);
            #~ throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        #~ }
        #~ elsif($row->get_column('component_id') != $args{component_id}) {
            #~ $errmsg = "Entity::Component->new : component_template_id does not belongs to component specified by component_id";
            #~ $log->error($errmsg);
            #~ throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        #~ }
    #~ }

    my $self = $class->SUPER::new(%$config);

    bless $self, $class;
    return $self;
}

sub getComponentId{
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['component_name','component_version']);
    
    my $adm = Administrator->new();

    $log->error(Dumper %args);
    my $component = $adm->{db}->resultset('ComponentType')->search(\%args)->single();

    return $component->get_column("component_id");
}

=head2 getInstance

=cut

sub getInstance {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);

    my $adm = Administrator->new();

    # Retreive the component type.
    my $component = $adm->{db}->resultset('Component')->find($args{id});
    my $comp_name = $component->component_type->get_column('component_name');
    my $comp_version = $component->component_type->get_column('component_version'); 
    my $comp_class = $class .'::'. $comp_name.$comp_version;
	my $location = General::getLocFromClass(entityclass => $comp_class);
	eval { require $location; };
    return $comp_class->get(id => $args{id});
}

sub getComponents {
    my $class = shift;

    my $adm = Administrator->new();

    my $components = $adm->{db}->resultset('ComponentType')->search();
    my $list = [];
    while(my $c = $components->next) {
        my $tmp = {};
        $tmp->{component_type_id}  = $c->get_column('component_type_id');
        $tmp->{component_name}     = $c->get_column('component_name');
        $tmp->{component_version}  = $c->get_column('component_version');
        $tmp->{component_category} = $c->get_column('component_category');
        push(@$list, $tmp);
    }
    return $list;
}

sub getComponentsByCategory {
    my $class = shift;

    my $adm = Administrator->new();

    my $components = $adm->{db}->resultset('ComponentType')->search({}, 
        { order_by => { -asc => [qw/component_category component_name component_version/]}});

    my $list = [];
    my $currentindex = -1;
    my $currentcategory = '';
    while(my $c = $components->next) {
        my $category = $c->get_column('component_category');
        my $tmp = { name => $c->get_column('component_name'), version => $c->get_column('component_version')};
        if($currentcategory ne $category) {
            $currentcategory = $category;
            $currentindex++;
            $list->[$currentindex] = {category => "$category", components => []};
        }
        push @{$list->[$currentindex]->{components}}, $tmp;
    }
    return $list;
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
    if( defined $template_id ) {
        return $self->{_dbix}->parent->component_template->get_column('component_template_directory');
    } else {
        return;
    }
}

=head2 getComponenAttr

B<Class>   : Public
B<Desc>    : This method return component information like name, version, ...
B<args>    : None
B<Return>  : Hash ref :
    B<component_name> : Component name
    B<component_version> : Component version
    B<component_id> : Component id. Could be use to instanciate a new cluster.
            Ref Component table id
    B<component_category> : Component category. Its a specific category classification be
B<Comment>  : Return information about component, not about $self (which is a component instance)
B<throws>  : None

=cut

sub getComponentAttr {
    my $self = shift;
    my $componentAttr = {};
    $componentAttr->{component_name}     = $self->{_dbix}->parent->component_type->get_column('component_name');
    $componentAttr->{component_type_id}  = $self->{_dbix}->parent->component_type->get_column('component_type_id');
    $componentAttr->{component_version}  = $self->{_dbix}->parent->component_type->get_column('component_version');
    $componentAttr->{component_category} = $self->{_dbix}->parent->component_type->get_column('component_category');
    return $componentAttr;
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

    my $component_name = $self->{_dbix}->component_type->get_column('component_name');
    my $component_version = $self->{_dbix}->component_type->get_column('component_version');

    return $component_name . " " . $component_version;
}

sub readyNodeAddition{return 1;}
sub readyNodeRemoving{return 1;}

# Method to override to insert in db component default configuration
sub insertDefaultConfiguration { }
sub getClusterizationType{}
sub getExecToTest{}
sub getNetConf{}
sub needBridge{ return 0; }
sub getHostConstraints {return;}
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
