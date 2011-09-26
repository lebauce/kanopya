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
=head1 NAME

<Entity::Component> <General class for component abstraction>

=head1 VERSION

This documentation refers to <Entity::Component> version 1.0.0.

=head1 SYNOPSIS

use <Entity::Component>;

my $component_instance_id = 2; # component instance id

Entity::Component->get(id=>$component_instance_id);

# Cluster id

my $cluster_id = 3;

# Component id are fixed, please refer to component id table

my $component_id =2 

Entity::Component->new(component_id=>$component_id, cluster_id=>$cluster_id);

=head1 DESCRIPTION

Entity::Component is an abstract class of component objects

=head1 METHODS

=cut
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

sub new {
    my $class = shift;
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['cluster_id','component_id']);
    
    my $admin = Administrator->new();
    my $template_id = undef;
    if(exists $args{component_template_id} and defined $args{component_template_id}) {
        $template_id = $args{component_template_id};
    }
    
    # check if component_id is valid
    my $row = $admin->{db}->resultset('Component')->find($args{component_id});
    if(not defined $row) {
        $errmsg = "Entity::Component->new : component_id does not exist";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # check if instance of component_id is not already inserted for  this cluster
    $row = $admin->{db}->resultset('ComponentInstance')->search(
        { component_id => $args{component_id}, 
          cluster_id => $args{cluster_id} })->single;
    if(defined $row) {
        $errmsg = "Entity::Component->new : cluster has already the component with id $args{component_id}";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # check if component_template_id correspond to component_id
    if(defined $template_id) {
        my $row = $admin->{db}->resultset('ComponentTemplate')->find($template_id);
        if(not defined $row) {
            $errmsg = "Entity::Component->new : component_template_id does not exist";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        } elsif($row->get_column('component_id') != $args{component_id}) {
            $errmsg = "Entity::Component->new : component_template_id does not belongs to component specified by component_id";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
    }
    # We create a new DBIx containing new entity
    my $self = $class->SUPER::new( attrs => \%args, table => "ComponentInstance");
    return $self;
}

=head2 get

B<Class>   : Public
B<Desc>    : This method allows to get an existing of component.
          This is an abstract class, DO NOT instantiate it.
B<args>    : 
    B<component_instance_id> : I<Int> : identify component instance 
B<Return>  : a new Entity::Component from Kanopya Database
B<Comment>  : To modify data in DB call save() on returned obj (after modification)
B<throws>  : 
    B<Kanopya::Exception::Internal::IncorrectParam> When missing mandatory parameters
    
=cut

sub get {
    my $class = shift;
    my %args = @_;

     General::checkParams(args => \%args, required => ['id']);

    if ((! exists $args{id} or ! defined $args{id})) { 
        $errmsg = "Entity::Component->get need an id named argument!";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
   my $self = $class->SUPER::get( %args, table=>"ComponentInstance");
   return $self;
}

=head2 getInstance

=cut

sub getInstance {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);
  
    my $adm = Administrator->new;
    my $comp_instance_row = $adm->{db}->resultset("ComponentInstance")->find(
     { component_instance_id => $args{id} }, 
     { '+columns' => [ "component.component_name",
                       "component.component_version",
                       "component.component_category"], 
     join => ["component"]}
    );
    
#    $class = "Entity::Component::".$comp_instance_row->get_column('component_category')."::" .
#                 $comp_instance_row->get_column('component_name') . 
#                 $comp_instance_row->get_column('component_version');
    $class = "Entity::Component::" . $comp_instance_row->get_column('component_name') 
                                   . $comp_instance_row->get_column('component_version');
   my $class_loc = General::getLocFromClass( entityclass => $class);
   require $class_loc;                  
   my $self = $class->get( %args, table=>"ComponentInstance");
   return $self;
}

=head2 delete

B<Class>   : Public
B<Desc>    : This method allows to delete a component
B<args>    : None
B<Return>  : Nothing
B<Comment>  : Delete Components
B<throws>  : Nothing
    
=cut

sub delete {
    my $self = shift;
    my $data = $self->{_dbix};
    
    my $entity_rs = $data->related_resultset( "entitylink" );
    $log->debug("First Deletion of entity link : component_instance_entity");
    # J'essaie de supprimer dans la table entity
    my $real_entity_rs = $entity_rs->related_resultset("entity");
    $real_entity_rs->delete;

    $log->debug("Finally delete the dbix itself");
    $data->delete;
}

sub getComponents {
    my $class = shift;
    my $adm = Administrator->new();
    my $components = $adm->{db}->resultset('Component')->search();
    my $list = [];
    while(my $c = $components->next) {
        my $tmp = {};
        $tmp->{component_id}       = $c->get_column('component_id');
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
    my $components = $adm->{db}->resultset('Component')->search({}, 
    { order_by => { -asc => [qw/component_category component_name component_version/]}}
    );
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
    if( defined $self->{_dbix}->get_column('component_template_id') ) {
        return $self->{_dbix}->component_template->get_column('component_template_directory');
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

    $componentAttr->{component_name} = $self->{_dbix}->component->get_column('component_name');
    $componentAttr->{component_id} = $self->{_dbix}->component->get_column('component_id');
    $componentAttr->{component_version} = $self->{_dbix}->component->get_column('component_version');
    $componentAttr->{component_category} = $self->{_dbix}->component->get_column('component_category');

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
    my $string = $self->{_dbix}->component->get_column('component_name')." ".$self->{_dbix}->component->get_column('component_version');
    return $string;
}

=head2 save

B<Class>   : Public
B<Desc>    : This method overload entity save to manage component specificity
        Overload reason is a technic point. (Name of table link with DBIX)
B<args>    : None
B<Return>  : String : Format : 'Component name' 'Component version'
B<Comment>  : None
B<throws>  : None

=cut

sub save {
    my $self = shift;
    my $data = $self->{_dbix};
    #TODO check rights

    my $component_instance_id;
    if ( $data->in_storage ) {
        # MODIFY existing db obj
        $data->update;
        $self->_saveExtendedAttrs();
    } else {
        # CREATE
        my $relation = lc(ref $self);
        $relation =~ s/.*\:\://g;
        $log->debug("The relation is: $relation");
        my $newentity = $self->{_dbix}->insert;
        $component_instance_id = $newentity->get_column("component_instance_id");
        $log->debug("new entity inserted.");
        my $adm = Administrator->new();
        my $row = $adm->{db}->resultset('Entity')->create({});
        my $row_entity = $adm->{db}->resultset("ComponentInstanceEntity")->create({
            entity_id => $row->get_column('entity_id'),
            "component_instance_id" => $component_instance_id});
        $log->debug("new $self inserted with his entity relation.");
        $self->{_entity_id} = $row->get_column('entity_id');

        $self->_saveExtendedAttrs();
        $log->info(ref($self)." saved to database");
    }

    return $component_instance_id;
}
sub readyNodeAddition{return 1;}
sub readyNodeRemoving{return 1;}

# Method to override to insert in db component default configuration
sub insertDefaultConfiguration { }
sub getClusterizationType{}
sub getExecToTest{}
sub getNetConf{}
sub needBridge{ return 0; }

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
