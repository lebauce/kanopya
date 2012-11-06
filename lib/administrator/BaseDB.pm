#    Copyright © 2012 Hedera Technology SAS
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

=pod

=begin classdoc

Base class to manage inheritance throw relational database.

@since    2012-Jun-10
@instance hash
@self     $self

=end classdoc

=cut

package BaseDB;

use strict;
use warnings;

use General;
use Administrator;

use Class::ISA;
use Hash::Merge;
use POSIX qw(ceil);
use vars qw($AUTOLOAD);

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("basedb");
my $errmsg;
my %class_type_cache;

use constant ATTR_DEF => {
    label => {
        is_virtual  => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        create => {
            description => 'create a new object',
            perm_holder => 'mastergroup',
        },
        remove => {
            description => 'remove an object',
            perm_holder => 'mastergroup',
        },
        update => {
            description => 'update an object',
            perm_holder => 'mastergroup',
        },
        get => {
            description => 'get an object',
            perm_holder => 'mastergroup',
        },
    };
}


=pod

=begin classdoc

@constructor

Create a new instance of the class. It inserts a entry for every class
of the hierarchy, every entry having a foreign key to its parent entry

@return a class instance

=end classdoc

=cut

sub new {
    my ($class, %args) = @_;
    my $hash = \%args;

    # Extract relation for futher handling
    my $relations = extractRelations(hash => $hash);

    my @attrs = keys %args;
    foreach my $attr (@attrs) {
        my $relation = $class->getAttrDefs->{$attr . "_id"};

        if ($relation && defined($relation->{relation}) && $args{$attr}->isa("BaseDB")) {
            $args{$attr . "_id"} = $args{$attr}->id;
            delete $args{$attr};
        }
    }

    my $attrs = $class->checkAttrs(attrs => $hash);

    # Get the class_type_id for class name
    my $adm = Administrator->new();
    eval {
        my $rs = $adm->_getDbixFromHash(table => "ClassType",
                                        hash  => { class_type => $class })->single;

        $attrs->{class_type_id} = $rs->get_column('class_type_id');
    };
    if ($@) {
        # Unregistred or abstract class, assuming it is not an Entity.
    }

    my $self = $class->newDBix(attrs => $attrs);
    bless $self, $class;

    # Populate relations
    $self->populateRelations(relations => $relations);

#    $self->{_altered} = 0;

    return $self;
}

=pod

=begin classdoc

Default label management
Label is the value of the attr returned by getLabelAttr() or the object id
Subclass can redefined this method to return specific label

@return the label string for this object

=end classdoc

=cut

sub label {
    my $self = shift;

    my $label = $self->getLabelAttr();
    return $label ? $self->getAttr(name => $label) : $self->id;
}

=pod

=begin classdoc

Update an instance by setting values for attribute taht differs,
also handle the update of relations.

@return the updated object

=end classdoc

=cut

sub update {
    my ($self, %args) = @_;
    my $hash = \%args;

    # Extract relation for futher handling
    my $relations = extractRelations(hash => $hash);
    delete $hash->{id};

    my $updated = 0;
    for my $attr (keys %$hash) {
        my $currentvalue = $self->getAttr(name => $attr);
        if ((defined $currentvalue and "$hash->{$attr}" ne "$currentvalue") or
            (not defined $currentvalue and defined $hash->{$attr})) {
            $self->setAttr(name => $attr, value => $hash->{$attr});

            if (not $updated) { $updated = 1; }
        }
    }
    if ($updated) { $self->save(); }

    # Populate relations
    $self->populateRelations(relations => $relations);
    return $self;
}


=pod

=begin classdoc

Extend an object instance to a concreter type.

@return the promoted object

=end classdoc

=cut

sub promote {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'promoted' ]);

    my $adm = Administrator->new();

    # Check if the new type is in the same hierarchy
    my $baseclass = ref($args{promoted});
    if (not ($class =~ m/$baseclass/)) {
        $errmsg = "Unable to promote " . ref($args{promoted}) . " to " . $class;
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    my $pattern = $baseclass . '::';
    my $subclass = $class;
    $subclass =~ s/^$pattern//g;

    # Set the primary key to the parent primary key value.
    my $primary_key = ($adm->{db}->source(_rootTable($subclass))->primary_columns)[0];
    $args{$primary_key} = $args{promoted}->id;

    # Merge the base object attributtes and new ones for attrs checking
    my %totalargs = (%args, $args{promoted}->getAttrs);
    delete $totalargs{promoted};

    # Then extract only the attrs for new tables for insertion
    my $attrs = $class->checkAttrs(attrs => \%totalargs,
                                   trunc => $baseclass . '::' . _rootTable($subclass));

    my $self = $class->newDBix(attrs => $attrs, subclass => $subclass);

    bless $self, $class;

    # Set the class type to the new promotion class
    eval {
        my $rs = $adm->_getDbixFromHash(table => "ClassType",
                                        hash  => { class_type => $class })->single;

        $self->setAttr(name => 'class_type_id', value => $rs->get_column('class_type_id'));
        $self->save();
    };
    if ($@) {
        # Unregistred or abstract class name <$class>, assuming it is not an Entity.
    }
    return $self;
}


=pod

=begin classdoc

Generalize an object instance to a parent type.

@return the demoted object

=end classdoc

=cut

sub demote {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'demoted' ]);

    my $adm = Administrator->new();

    # Check if the new type is in the same hierarchy
    my $baseclass = ref($args{demoted});
    if (not ($baseclass =~ m/$class/)) {
        $errmsg = "Unable to demote " . ref($args{demoted}) . " to " . $class;
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    # Delete row of tables bellow $class
    $args{demoted}->delete(trunc => $class);

    bless $args{demoted}, $class;

    # Set the class type to the new promotion class
    eval {
        my $rs = $adm->_getDbixFromHash(table => "ClassType",
                                        hash  => { class_type => $class })->single;

        $args{demoted}->setAttr(name => 'class_type_id', value => $rs->get_column('class_type_id'));
        $args{demoted}->save();
    };
    if ($@) {
        # Unregistred or abstract class name <$class>, assuming it is not an Entity.
    }
    return $args{demoted};
}

=pod

=begin classdoc

Build the full list of methods by concatenating methods hash of each classes
in the hierarchy, it also support miulti inherintance by using Class::ISA::self_and_super_path.

@return the hash of methods exported to the api for this class.

=end classdoc

=cut

sub getMethods {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $methods = {};
    my @supers  = Class::ISA::self_and_super_path($class);
    my $merge   = Hash::Merge->new();

    for my $sup (@supers) {
        if ($sup->can('methods')) {
            $methods = $merge->merge($methods, $sup->methods());
        }
     }
     return $methods;
}


=pod

=begin classdoc

Return a hash ref containing all ATTR_DEF for each class in the hierarchy.

@optional group_by outpout hash format policy (module|none)

@return the updated object

=end classdoc

=cut

sub getAttrDefs {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'group_by' => 'none' });

    my $attributedefs = {};
    my $modulename = $class;
    my @hierachy = $class->getClassHierarchy;

    while(@hierachy) {
        my $attr_def = {};

        if ($modulename ne "BaseDB") {
            requireClass($modulename);

            eval {
                $attr_def = $modulename->getAttrDef();
            };

            my $schema;
            eval {
                $schema = $class->{_dbix}->result_source();
            };
            if ($@) {
                my $adm = Administrator->new();
                $schema = $adm->{db}->source(_buildClassNameFromString($modulename));
            }

            my @relnames = $schema->relationships();
            for my $relname (@relnames) {
                my $relinfo = $schema->relationship_info($relname);
                if ($relname ne "parent" &&
                    $relinfo->{attrs}->{is_foreign_key_constraint} &&
                    $schema->has_column($relname . "_id") && not defined ($relname . "_id")) {

                    $attr_def->{$relname . "_id"} = {
                        type         => 'relation',
                        relation     => $relinfo->{attrs}->{accessor},
                        pattern      => '^\d*$',
                        is_mandatory => 0,
                    };
                }
            }

            for my $column ($schema->columns) {
                if (not defined ($attr_def->{$column})) {
                    $attr_def->{$column} = {
                        pattern      => '^.*$',
                        is_mandatory => 0,
                    };
                    if (grep { $_ eq $column } @{$schema->_primaries}) {
                        $attr_def->{$column}->{is_primary} = 1;
                    }
                }
            }
        }

        if ($attr_def) {
            $attributedefs->{$modulename} = $attr_def;
        }

        if (scalar(@hierachy) > 1) {
            $modulename = _parentClass($modulename);
        }

        pop @hierachy;
    }

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

    # Add the BaseDB attrs to the upper class attrs
    $attributedefs->{$modulename} = $merge->merge($attributedefs->{$modulename}, BaseDB::getAttrDef());

    if ($args{group_by} eq 'module') {
        return $attributedefs;
    }

    # Finally merge all module attrs into one level hash
    my $result = {};
    foreach my $module (keys %$attributedefs) {
        $result = $merge->merge($result, $attributedefs->{$module});
    }

    return $result;
}


=pod

=begin classdoc

Check the value of an attrbiute with the pattertn defined in the ATTR_DEF.

@param name the name of the attribute to check the value
@param value the value to check with pattern

=end classdoc

=cut

sub checkAttr {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'name' ], optional => {'value' => undef});

    my $attributes_def = $class->getAttrDefs();
    if (exists $attributes_def->{$args{name}} && defined $args{value} &&
        $args{value} !~ m/($attributes_def->{$args{name}}->{pattern})/) {

        $errmsg = "$class"."->checkAttr detect a wrong value $args{value} for param: $args{name} on class $class";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}


=pod

=begin classdoc

Check attributes validity in the class hierarchy and build as the same time
a hasref structure to pass to 'new' method of dbix resultset for
the root class of the hierarchy.

@param attrs hash containing keys/values of attributes to check
@optional trunc a class name with its hierachy, allows to return
          a sub hash exluding attributes of classes in this hierachy.

@return the hash of keys/values of attributes of each module in the class hierachy,
        sorted by module name.

=end classdoc

=cut

sub checkAttrs {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;
    my $final_attrs = {};

    General::checkParams(args => \%args, required => [ 'attrs' ], optional => { 'trunc' => undef });

    my $attributes_def = $class->getAttrDefs(group_by => 'module');
    foreach my $module (keys %$attributes_def) {
        $final_attrs->{$module} = {};
    }

    my $attrs = $args{attrs};
    # search unknown attribute or invalid value attribute
    ATTRLOOP:
    foreach my $attr (keys(%$attrs)) {
        foreach my $module (keys %$attributes_def) {
            if (exists $attributes_def->{$module}->{$attr}){
                my $value = $attrs->{$attr};
                my $pattern = $attributes_def->{$module}->{$attr}->{pattern};

                if (((not defined $value) and $attributes_def->{$module}->{$attr}->{is_mandatory}) or
                    ((defined $value and defined $pattern) and $value !~ m/($pattern)/)) {
                    $errmsg = "$class"."->checkAttrs detect a wrong value ($value) for param : $attr on class $module";
                    throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
                }
                $final_attrs->{$module}->{$attr} = $value;
                next ATTRLOOP;
            }
        }
        $errmsg = "$class" . "->checkAttrs detect a wrong attr $attr !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }

    # search for non provided mandatory attribute and set primary keys to undef
    foreach my $module (keys %$attributes_def) {
        foreach my $attr (keys(%{$attributes_def->{$module}})) {
            if (($attributes_def->{$module}->{$attr}->{is_mandatory}) && (! exists $attrs->{$attr})) {
                $errmsg = "$class" . "->checkAttrs detect a missing attribute $attr (on $module)!";
                $log->error($errmsg);
                throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
            }
        }
    }

    my @modules = sort keys %$final_attrs;
    # finaly restructure the hashref with dbix relationships
    for my $i (0..$#modules-1) {
        my $relation = _classToTable(_buildClassNameFromString($modules[$i+1]));
        $final_attrs->{$modules[$i]}->{$relation} = $final_attrs->{$modules[$i+1]};
    }

    # If trunc is defined, only return a sub hash
    my $result = $final_attrs->{$modules[0]};
    if (defined $args{trunc}) {
        my $trunc = $args{trunc};

        while ($trunc =~ m/\:\:/) {
            $trunc = _childClass($trunc);
            my $classname = $trunc;
            $classname =~ s/\:\:.*//g;

            $result = $result->{_classToTable($classname)};
        }
    }

    return $result;
}


=pod

=begin classdoc

Build a new dbix from class name and attributes, and insert it in database.

@param attrs hash containing keys / values of the new dbix attributes
@optional subclass a class name to force building a sub type dbix of the class.

@return the object hash with the private _dbix.

=end classdoc

=cut

sub newDBix {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'attrs' ],
                         optional => { 'subclass' => $class });

    my $adm = Administrator->new();
    my $dbixroot = $adm->_newDbix(table => _rootTable($args{subclass}), row => $args{attrs});

    eval {
        $dbixroot->insert;
    };
    if ($@) {
        $errmsg = $@;

        # Try to extract the reason msg only
        $errmsg =~ s/\[.*$//g;
        $errmsg =~ s/^.*://g;
        throw Kanopya::Exception::DB(error => "Unable to create a new $class: " .  $errmsg);
    }

    return {
        _dbix => $adm->getRow(
                     table => _buildClassNameFromString($class),
                     id    => getRowPrimaryKey(row => $dbixroot),
                 )
    };
}


=pod

=begin classdoc

Construct the proper BaseDB based instance from a DBIx row

@param row a dbix row representing the object table row

@return the object instance.

=end classdoc

=cut

sub fromDBIx {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'row' ]);

    my $modulename = classFromDbix($args{row}->result_source);

    eval {
        requireClass($modulename);
    };
    if ($@) {
        my $err = $@;

        # Ugly fix to be able to require inner classes of components.
        # From the dbix row, we can retrieve the class name only, but inner classes
        # of components, that simply directly inherit from BaseDB, are located in
        # a sub directory of the component directory (lib/administrator/Entity/Component)
        # in funtion of the name of the component that belongs to.
        #
        # So if a required failled on a location builder by classFromDbix, try to
        # consider the module as a inner class of a component, by deducing the location
        # from the class name. E.g. with the class name Opennebula3Hypervisor, we can 
        # deduce the location: lib/administrator/Entity/Component/Opennebula3/.
        if (not $modulename =~ m/Entity/ and $modulename =~ m/\d/) {
            (my $component = $modulename) =~ s/\d.*//g;
            (my $version   = $modulename) =~ s/[a-zA-Z]*//g;

            $modulename = 'Entity::Component::' . $component . $version . '::' . $modulename;
            eval {
                requireClass($modulename);
            };
            if ($@) {
                # The module seems not to be a inner class of a component
                # re-throw the original exception.
                throw $err;
            }
        } else {
            my $basedb = bless { _dbix => $args{row} }, "BaseDB";
            return $basedb;
        }
    }

    # TODO: We need to use prefetch to get the parent/childs attrs,
    #       and use the concrete class type. Use 'get' for instance.

    return bless {
        _dbix      => $args{row},
    }, $modulename;

    # return $modulename->get(id => getRowPrimaryKey(row => $args{row}));
}


=pod

=begin classdoc

Retrieve a value given a name attribute, search this atribute throw the whole class hierarchy.

@param name name of the attribute to get the value

@return the attribute value

=end classdoc

=cut

sub getAttr {
    my $self  = shift;
    my $class = ref($self);
    my %args  = @_;

    General::checkParams(args => \%args, required => ['name']);

    my $dbix = $self->{_dbix};
    my $attr = $class->getAttrDefs()->{$args{name}};
    my $value = undef;
    my $found = 1;

    # Recursively search in the dbix objets, following
    # the 'parent' relation
    while ($found) {
        # The attr is a column
        if ($dbix->has_column($args{name})) {
            $value = $dbix->get_column($args{name});
            last;
        }
        # The attr is a relation
        elsif ($dbix->has_relationship($args{name})) {
            my $name = $args{name};
            my $relinfo = $dbix->relationship_info($args{name});
            if ($relinfo->{attrs}->{accessor} eq "multi") {
                return map { fromDBIx(row => $_) } $dbix->$name;
            }
            else {
                if ($dbix->$name) {
                    $value = fromDBIx(row => $dbix->$name);
                }
            }
            last;
        }
        # The attr is a many to many relation
        elsif ($dbix->can($args{name})) {
            my $name = $args{name};
            return map { fromDBIx(row => $_) } $dbix->$name;
        }
        # The attr is a virtual attr
        elsif (($self->can($args{name}) or $self->can(normalizeMethod($args{name}))) and
               defined $attr and $attr->{is_virtual}) {

            my $method = $args{name};
            # Firstly try to call method with camel-case style
            eval {
                my $camelcased_method = normalizeMethod($method);
                $value = $self->$camelcased_method();
            };
            if ($@) {
                # If failled with camel-cased, try the original attr name as method
                $value = $self->$method();
            }
            last;
        }
        elsif ($dbix->can('parent')) {
            $dbix = $dbix->parent;
            next;
        }
        else {
            $found = 0;
            last;
        }
    }

    if (not $found) {
        $errmsg = ref($self) . " getAttr no attr name $args{name}!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    return $value;
}


=pod

=begin classdoc

Retrieve all keys/values in the class hierarchy

@return a hash containing all object attributes with values

=end classdoc

=cut

sub getAttrs {
    my ($self) = @_;
    my $dbix = $self->{_dbix};

   # build hash corresponding to class table (with local changes)
   my %attrs = ();
       while(1) {
        # Search for attr in this dbix
        my %currentattrs = $dbix->get_columns;
        %attrs = (%attrs, %currentattrs);
        if($dbix->can('parent')) {
            $dbix = $dbix->parent;
            next;
        } else {
            last;
        }
    }

   return %attrs;
}


=pod

=begin classdoc

Set one name attribute with the given value, search this attribute throw the whole
class hierarchy, and check attribute validity.

@param name the name of the attribute to set the value
@param value the value to set

@return the value set

=end classdoc

=cut

sub setAttr {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'name' ], optional => { 'value' => undef });

    my ($name, $value) = ($args{name}, $args{value});
    my $dbix = $self->{_dbix};
    $self->checkAttr(%args);

    my $found = 0;
    while(1) {
        # Search for attr in this dbix
        if ($dbix->has_column($name)) {
            $dbix->set_column($name, $value);
            $found = 1;
            last;
        } elsif($dbix->can('parent')) {
            # go to parent dbix
            $dbix = $dbix->parent;
            next;
        } else {
            last;
        }
    }

    if (not $found) {
        $errmsg = ref($self) . " setAttr no attr name $args{name}!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

#    $self->{_altered} = 1;

    return $value;
}


=pod

=begin classdoc

Retrieve one instance from an id

@param id the id of the object to get

@return the object instance

=end classdoc

=cut

sub get {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'id' ]);

    my $adm = Administrator->new();
    eval {
        my $dbix = $adm->getRow(id => $args{id}, table => _rootTable($class));
        $class   = $dbix->class_type->get_column('class_type');
    };
    if ($@) {
        $log->debug("Unable to retreive concrete class name, using $class.");
    }

    # Try to use the corresponding module
    requireClass($class);

    my $table = _buildClassNameFromString($class);
    my $dbix = $adm->getRow(id => $args{id}, table => $table);
    my $self = {
        _dbix => $dbix,
    };

    bless $self, $class;

    return $self;
}


=pod

=begin classdoc

Return the class type name from a class type id, at the first call,
get all the entries and cache them into a hash for *LOT* faster accesses.

@param id the id of the class type

@return the class type name

=end classdoc

=cut

sub getClassType {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'id' ]);

    my $adm = Administrator->new();
    if (not %class_type_cache) {
        my $class_types = $adm->_getDbixFromHash(table => "ClassType",
                                                 hash  => { });
        while (my $class_type = $class_types->next) {
            $class_type_cache{$class_type->get_column("class_type_id")} =
                $class_type->get_column("class_type");
        }
    }

    return $class_type_cache{$args{id}};
}


=pod

=begin classdoc

Build the join query required to get all the attributes of the whole class hierarchy.

@return the join query

=end classdoc

=cut

sub getJoin {
    my ($class) = @_;
    my $adm = Administrator->new();

    my @hierarchy = $class->getClassHierarchy;
    my $depth = scalar @hierarchy;

    my $current = $depth;
    my $parent_join;
    while ($current > 0) {
        last if $hierarchy[$current - 1] eq "BaseDB";
        $parent_join = $adm->{db}->source($hierarchy[$current - 1])->has_relationship("parent") ?
                           ($parent_join ? { parent => $parent_join } : { "parent" => undef }) :
                           $parent_join;
        $current -= 1;
    }

    return $parent_join;
}


=pod

=begin classdoc

Build the JOIN query to get the attributes of a multi level depth relationship.

@return the join query

=end classdoc

=cut

sub getJoinQuery {
    my ($class, %args) = @_;

    my @comps = @{$args{comps}};
    my $source = $class->getResultSource;
    my $on = "";
    my $relation;

    my @joins;
    for my $comp (@comps) {
        my @segment = ();
        while (! $source->has_relationship($comp)) {
            if ($args{reverse}) {
                $relation = $source->reverse_relationship_info("parent");
                @segment = ((keys %$relation)[0], @segment);
            }
            else {
                @segment = ("parent", @segment);
            }
            last if ! $source->has_relationship("parent");
            $source = $source->related_source("parent");
        }

        if ($args{reverse}) {
            $relation = $source->reverse_relationship_info($comp);
            my $name = (keys %$relation)[0];
            @joins = ($name, @segment, @joins);
            if (!$on) {
                $on = $name . "." . ($relation->{$name}->{source}->primary_columns)[0];
            }
        }
        else {
            @joins = (@joins, @segment, $comp);
        }

        $source = $source->related_source($comp);
    }

    # Get all the hierarchy of the relation
    my @indepth;
    if ($args{indepth}) {
        my $depth_source = $source;
        while ($depth_source->has_relationship("parent")) {
            @indepth = ("parent", @indepth);
            $depth_source = $depth_source->related_source("parent");
        }
    }
    @joins = (@joins, @indepth);

    my $joins;
    for my $comp (reverse @joins) {
        $joins = { $comp => $joins };
    }

    return { source => $source,
             join   => $joins,
             on     => $on };
}


=pod

=begin classdoc

Return the entries that match the 'hash' filter. It also accepts more or less
the same parameters than DBIx 'search' method. It fetches the attributes of
the whole class hierarchy and returns an object as a BaseDB derived object.

@param hash the keys/values describing the researched objects
@optional page the number of the requested page among all pages
          of the object list.
@optional rows the number of object entry in a page
@optional order_by the sorting policy for output list
@optional dataType the output format

@return the matching object list

=end classdoc

=cut

sub search {
    my ($class, %args) = @_;
    my @objs = ();

    General::checkParams(args     => \%args,
                         required => [ 'hash' ],
                         optional => { 'page' => undef, 'rows' => undef, 'join' => undef,
                                       'order_by' => undef, 'dataType' => undef,
                                       'prefetch' => [ ], 'raw_hash' => { } });

    my $table = _buildClassNameFromString($class);
    my $adm   = Administrator->new();

    my $merge = Hash::Merge->new('STORAGE_PRECEDENT');
    my $prefetch = $class->getJoin() || {};
    $prefetch = $merge->merge($prefetch, $args{join});
    my $source = $class->getResultSource;
    for my $relation (@{$args{prefetch}}) {
        my @comps = split(/\./, $relation);
        $prefetch = $merge->merge($prefetch, $class->getJoinQuery(comps   => \@comps,
                                                                  indepth => 1)->{join});
    }

    for my $filter (keys %{$args{hash}}) {
        next if substr($filter, 0, 3) eq "me.";
        my @comps = split('\.', $filter);
        my $value = $args{hash}->{$filter};

        if (scalar (@comps) > 1) {
            my $value = $args{hash}->{$filter};
            my $attr = pop @comps;

            delete $args{hash}->{$filter};

            $prefetch = $merge->merge($prefetch, $class->getJoinQuery(comps => \@comps)->{join});
            $args{hash}->{$comps[-1] . '.' . $attr} = $value;
        }
    }

    $args{hash} = $merge->merge($args{hash}, $args{raw_hash});

    my $rs = $adm->_getDbixFromHash('table' => $table,      'hash'     => $args{hash},
                                    'page'  => $args{page}, 'prefetch' => $prefetch,
                                    'rows'  => $args{rows}, 'order_by' => $args{order_by});

    while (my $row = $rs->next) {
        my $obj = { _dbix => $row };

        my $parent = $row;
        while ($parent->can('parent')) {
            $parent = $parent->parent;
        }

        my $class_type;
        if ($parent->has_column("class_type_id") and $class ne "ClassType") {
            $class_type = getClassType(id => $parent->get_column("class_type_id"));

            if (length($class_type) > length($class)) {
                requireClass($class_type);
                $obj = $class_type->get(id => $parent->get_column("entity_id"));
            } else {
                bless $obj, $class_type;
            }
        }
        else {
            $class_type = $class;
            bless $obj, $class_type;
        }

        if($@) {
            my $exception = $@;
            if(Kanopya::Exception::Permission::Denied->caught()) {
                $log->debug("no right to access to object <$table> with <$row->id>");
                next;
            }
            else { $exception->rethrow(); }
        }
        else {
            push @objs, $obj;
        }
    }

    if (defined ($args{dataType}) and $args{dataType} eq "hash") {
        my $total = (defined ($args{page}) or defined ($args{rows})) ?
                        $rs->pager->total_entries : $rs->count;

        return {
            page    => $args{page} || 1,
            pages   => ceil($total / ($args{rows} || ($args{page} ? 10 : 1))),
            records => scalar @objs,
            rows    => \@objs,
            total   => $total,
        }
    }

    return wantarray ? @objs : \@objs;
}

sub searchRelated {
    my ($self, %args) = @_;
    my $class = ref ($self) || $self;

    General::checkParams(args     => \%args,
                         required => [ 'filters' ],
                         optional => { 'hash' => { } });

    my $adm = Administrator->new();
    my $source = $adm->{db}->source(_buildClassNameFromString($class));
    my $join = $class->getJoinQuery(comps   => $args{filters},
                                    reverse => 1);
    my $searched_class = classFromDbix($join->{source});
    requireClass($searched_class);

    return $searched_class->search(%args, raw_hash => { $join->{on} => $args{id} },
                                          hash     => $args{hash},
                                          join     => $join->{join});
}

=pod

=begin classdoc

Return a single element matching the specified criterias take the same arguments as 'search'.

@return the matching object

=end classdoc

=cut

sub find {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'hash' ]);

    my @objects = $class->search(%args);

    my $object = pop @objects;
    if (! defined $object) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "No entry found for " . $class . ", with hash " . Dumper($args{hash})
              );
    }
    return $object;
}


=pod

=begin classdoc

Return a single element matching the specified criterias take the same arguments as 'search'.

@return the matching object

=end classdoc

=cut

sub save {
    my ($self) = @_;
    my $dbix = $self->{_dbix};

    my $id;
    if ( $dbix->in_storage ) {
        $dbix->update;
        while ($dbix->can('parent')) {
            $dbix = $dbix->parent;
            $dbix->update;
        }
    } else {
        $errmsg = "$self" . "->save can't be called on a non saved instance! (new has not be called)";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    return $id;
}


=pod

=begin classdoc

Remove records from the entire class hierarchy.

@optional trunc a class name with its hierachy, allows to delete
          a part of the class hierachy only.

=end classdoc

=cut

sub delete {
    my ($self, %args) = @_;
    my $dbix = $self->{_dbix};

    General::checkParams(args => \%args, optional => { 'trunc' => undef });

    if (defined $args{trunc}) {
        $args{trunc} = _buildClassNameFromString($args{trunc});
    }

    # Search for first mother table in the hierarchy
    while(1) {
        if ($dbix->can('parent')) {
            my $parentclass = _buildClassNameFromString(ref($dbix->parent));

            if (defined $args{trunc} and $parentclass eq $args{trunc}) {
                last;
            }

            # go to parent dbix
            $dbix = $dbix->parent;
            next;

        } else { last; }
    }
    $dbix->delete;
}


=pod

=begin classdoc

Generic method to build the string representation of the object.

@return the string the representing the object

=end classdoc

=cut

sub toString {
    my $self = shift;
    return ref($self);
}


=pod

=begin classdoc

Return the object as a hash so that it can be safely be converted to JSON.
Should be named differently but hey...

@optional model switch to model mode, return the object description
          instead of attributes values
@optional no_relations force to remove the relations from the atrribute definition

@return the hash representing the object or the model depending on $args{model} option

=end classdoc

=cut

sub toJSON {
    my ($self, %args) = @_;
    my $class = ref ($self) || $self;

    General::checkParams(args     => \%args,
                         optional => { 'no_relations' => 0, 'model' => undef, 'raw' => 0 });

    my $pk;
    my $hash = {};
    my $attributes;
    my $conreteclass = $class;
    my $merge = Hash::Merge->new();

    $attributes = $class->getAttrDefs(group_by => 'module');
    foreach my $class (keys %$attributes) {
        foreach my $attr (keys %{$attributes->{$class}}) {
            next if ($args{raw} && $attributes->{$class}->{$attr}->{is_virtual});

            if (defined $args{model}) {
                # Only add primary key attrs from the lower class in the hierarchy
                if (not ($attributes->{$class}->{$attr}->{is_primary} and $class ne $conreteclass)) {
                    $hash->{attributes}->{$attr} = $attributes->{$class}->{$attr};
                }
            }
            else {
                if ((not $args{no_empty}) or (defined $self->getAttr(name => $attr))) {
                    $hash->{$attr} = $self->getAttr(name => $attr);
                }
            }
        }
    }

    if ($args{model}) {
        my $table = _buildClassNameFromString($class);
        my $adm = Administrator->new();
        my @hierarchy = split(/::/, $class);
        my $depth = scalar @hierarchy;
        my $current = $depth;
        my $parent;

        for (my $current = $depth - 1; $current >= 0; $current--) {
            $parent = $adm->{db}->source($hierarchy[$current]);
            my @relnames = $parent->relationships();
            for my $relname (@relnames) {
                my $relinfo = $parent->relationship_info($relname);

                if (scalar (grep { $_ eq (split('::', $relinfo->{source}))[-1] } @hierarchy) == 0 and
                    $relinfo->{attrs}->{is_foreign_key_constraint} or
                    $relinfo->{attrs}->{accessor} eq "multi") {

                    my $resource = lc((split("::", $relinfo->{class}))[-1]);
                    $resource =~ s/_//g;

                    $hash->{relations}->{$relname} = $relinfo;
                    $hash->{relations}->{$relname}->{from} = $hierarchy[$current];
                    $hash->{relations}->{$relname}->{resource} = $resource;

                    # We must have relation attrs within attrdef to keep
                    # informations as label, is_editable and is_mandatory.
                    # Except if we explicitly don't want it (no_relations option)

                    if ($args{no_relations}) {
                        delete $hash->{attributes}->{$relname . "_id"};
                    }
                }
            }
            pop @hierarchy;
        }
        $hash->{methods} = $self->getMethods;

        $hash->{pk} = {
            pattern      => '^\d*$',
            is_mandatory => 1,
            is_extended  => 0
        };
    }
    else {
        if (!$args{raw}) {
            $hash->{pk} = $self->id;
        }
    }

    return $hash;
}

=pod

=begin classdoc

Extract relations sub hashes from the hash represeting the object.

@param hash hash representing the object.

@return the original hash containing the relations sub hashes only

=end classdoc

=cut

sub extractRelations {
    my (%args) = @_;

    General::checkParams(args => \%args, required => [ 'hash' ]);

    # Extrating relation from attrs
    my $relations = {};
    for my $attr (keys %{$args{hash}}) {
        if (ref($args{hash}->{$attr}) eq 'ARRAY') {
            $relations->{$attr} = delete $args{hash}->{$attr};
        }
    }
    return $relations;
}


=pod

=begin classdoc

Create or update relations. If a relation has the primary key set in this attributes,
we update the object, create it instead.

@param relations hash containing object relations only

=end classdoc

=cut

sub populateRelations {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'relations' ]);

    # For each relations type
    for my $relation (keys %{$args{relations}}) {
        my $attrdef = $class->getAttrDefs->{$relation};
        my $reldef  = $self->{_dbix}->relationship_info($relation);

        # Deduce the foreign key from relation def
        my @conds = keys %{$reldef->{cond}};
        my $fk = getForeignKeyFromCond(cond => $conds[0]);

        my $relation_schema = $self->{_dbix}->$relation->result_source;
        my $relationclass = classFromDbix($relation_schema);

        requireClass($relationclass);

        # Deduce the foreign key attr for link entries in relations multi
        my $linkfk;
        my $exsting = {};
        if ($attrdef->{relation} eq 'single_multi') {
            my @entries = $relationclass->search(hash => { $fk => $self->id });
            %$exsting = map { $_->id => $_ } @entries;
        }
        elsif ($attrdef->{relation} eq 'multi') {
            my $linked_reldef = $relation_schema->relationship_info($attrdef->{link_to});

            my @conds = values %{$linked_reldef->{cond}};
            $linkfk = getKeyFromCond(cond => $conds[0]);

            my @entries = $relationclass->search(hash => { $fk => $self->id });
            %$exsting = map { $_->id => $_ } @entries;
        }

        # Create/update all entries
        for my $entry (@{$args{relations}->{$relation}}) {
            if ($attrdef->{relation} eq 'single_multi') {
                my $id = delete $entry->{@{$relation_schema->_primaries}[0]};
                if ($id) {
                    # We have the relation id, it is a relation update
                    $relationclass->get(id => $id)->update(%$entry);
                    delete $exsting->{$id};
                }
                else {
                    # Create the new relationships
                    $entry->{$fk} = $self->id;
                    # Id do not exists, it is a relation creation
                    $relationclass->create(%$entry);
                }
            }
            elsif ($attrdef->{relation} eq 'multi') {
                my $exists = delete $exsting->{$entry};
                if (not $exists) {
                    # Create entries in the link table
                    $relationclass->create($fk => $self->id, $linkfk => $entry);
                }
            }
        }

        # Finally delete remaining entries
        for my $remaning (values %$exsting) {
            $remaning->remove();
        }
    }
}


=pod

=begin classdoc

Return the primary(ies) key(s) of a row.

@param row hash dbix row of the object

@return the primary key value

=end classdoc

=cut

sub getRowPrimaryKey {
    my (%args) = @_;

    General::checkParams(args => \%args, required => [ 'row' ]);

    # If the primary key is multiple, gevie the array ref to the get function
    my $id;
    my @multiple_id = $args{row}->id;
    if (scalar(@multiple_id) > 1) {
        $id = \@multiple_id;
    } else {
        $id = $multiple_id[0];
    }
    return $id;
}


=pod

=begin classdoc

Generic method to get the name of the attribute that identify the object.
Search for an attribute ending by '_name' within all attributes.

@optional attrs the attribute defintion of the object

@return the name of the attribute that identify the object

=end classdoc

=cut

sub getLabelAttr {
    my ($self, %args) = @_;
    my $class = ref ($self) || $self;

    General::checkParams(args => \%args, optional => { 'attrs' => $class->getAttrDefs });

    my @keys = keys %{$args{attrs}};

    my @attrs = grep { $_ =~ m/.*_name$/ } @keys;

    if (scalar @attrs) {
        return $attrs[0];
    }
    return undef;
}


=pod

=begin classdoc

Generic method for object creation.

@return the created object instance

=end classdoc

=cut

sub create {
    my $class = shift;
    my %args = @_;

    return $class->new(%args);
}


=pod

=begin classdoc

Generic method for object deletion.

=end classdoc

=cut

sub remove {
    my $self = shift;
    my %args = @_;

    $self->delete();
}


=pod

=begin classdoc

Get the primary key column name

@return the primary key column name.

=end classdoc

=cut

sub getPrimaryKey {
    my $self = shift;

    return ($self->{_dbix}->result_source->primary_columns)[0];
}


=pod

=begin classdoc

Parse ths dbix object relation definition to extract the foreign key
of the relation that link it to the object.

@param cond the 'cond' value of the dbix relation desciption hash

@return the foreign key name of the relation

=end classdoc

=cut

sub getForeignKeyFromCond {
    my (%args) = @_;

    General::checkParams(args => \%args, required => [ 'cond' ]);

    $args{cond} =~ s/.*foreign\.//g;
    return $args{cond};
}


=pod

=begin classdoc

Parse ths dbix object relation definition to extract the foreign key
of the relation that link it to the object.

@param cond the 'cond' value of the dbix relation desciption hash

@return the foreign key name of the relation

=end classdoc

=cut

sub getKeyFromCond {
    my (%args) = @_;

    General::checkParams(args => \%args, required => [ 'cond' ]);

    $args{cond} =~ s/.*self\.//g;
    return $args{cond};
}


=pod

=begin classdoc

Build an array of the full class hierachy. Module names follow the usual
perl module hierachy, except some exceptions:

- Components should come with their own classes that directly inherit from
  BaseDB, but those classes are located in a sub directory of the Component directory.

@return the array containing all classes in the hierarchy.

=end classdoc

=cut

sub getClassHierarchy {
    my $class = shift;

    my $classpath = (split("=", "$class"))[0];
    my @hierarchy = split(/::/, $classpath);

    if (defined $hierarchy[-3] and $hierarchy[-3] eq 'Component') {
        return _buildClassNameFromString($class);
    }
    return wantarray ? @hierarchy : \@hierarchy;
}


=pod

=begin classdoc

@deprecated

Get the primary key of the object

@return the primary key value

=end classdoc

=cut

sub getId {
    my $self = shift;

    return $self->id;
}


=pod

=begin classdoc

Get the primary key of the object

@return the primary key value

=end classdoc

=cut

sub id {
    my $self = shift;

    return $self->{_dbix}->get_column($self->getPrimaryKey);
}


=pod

=begin classdoc

@param $class the full class name with the hierachy

@return the parent class name

=end classdoc

=cut

sub _parentClass {
    my ($class) = @_;
    $class =~ s/\:\:[a-zA-Z0-9]+$//g;
    return $class;
}


=pod

=begin classdoc

@param $class the full class name with the hierachy

@return the class name at the bottom of the hierarchy

=end classdoc

=cut

sub _childClass {
    my ($class) = @_;
    $class =~ s/^[a-zA-Z0-9]+\:\://g;
    return $class;
}


=pod

=begin classdoc

@param $class the full class name with the hierachy

@return the class name without its hierarchy

=end classdoc

=cut

sub _buildClassNameFromString {
    my ($class) = @_;
    $class =~ s/.*\:\://g;
    return $class;
}


=pod

=begin classdoc

@param $class the full class name with the hierachy

@return the class name at the top of the hierarchy of a full class name.

=end classdoc

=cut

sub _rootTable {
    my ($class) = @_;

    $class = join('::', $class->getClassHierarchy);
    $class =~ s/\:\:.*$//g;
    return $class;
}


=pod

=begin classdoc

Convert a class name to table name

@param $class the full class name with the hierachy

@return the table name

=end classdoc

=cut

sub _classToTable {
    my ($class) = @_;

    $class =~ s/([A-Z])/_$1/g;
    my $table = lc( substr($class, 1) );

    return $table;
}


=pod

=begin classdoc

Normalize the specified name by removing underscores and upper casing
the characters that follows.

@param $name any name of database table

@return the normalized name

=end classdoc

=cut

sub normalizeName {
    my $name = shift;
    $name = normalizeMethod($name);

    return ucfirst($name);
};


=pod

=begin classdoc

Normalize the specified name by removing underscores and upper casing
the characters that follows, excepted the first character.

@param $name any name

@return the normalized name

=end classdoc

=cut

sub normalizeMethod {
    my $name = shift;
    my $i = 0;
    while ($i < length($name)) {
        if (substr($name, $i, 1) eq "_") {
            $name = substr($name, 0, $i) . ucfirst(substr($name, $i + 1, 1)) . substr($name, $i + 2)
        }
        $i += 1;
    }

    return $name;
};


=pod

=begin classdoc

Build the name of the Kanopya class for the specified DBIx table schema.

@param $source a dbix result source

@return the class name

=end classdoc

=cut

sub classFromDbix {
    my $source = shift;
    my $args = @_;

    my $name = ucfirst($source->from);

    while (1) {
        last if not $source->has_relationship("parent");
        $source = $source->related_source("parent");
        $name = ucfirst($source->from) . "::" . $name;
    }
    return normalizeName($name);
}

=pod

=begin classdoc

Return the DBIx ResultSource for this class.

=end classdoc

=cut

sub getResultSource {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $adm = Administrator->new();
    return $adm->{db}->source(_buildClassNameFromString($class));
}

=pod

=begin classdoc

Dinamically load a module from the class name.

@param $class Class name corresponding to the module to load.

=end classdoc

=cut

sub requireClass {
    my $class = shift;
    my $location = General::getLocFromClass(entityclass => $class);

    eval { require $location; };
    if ($@) {
        throw Kanopya::Exception::Internal::UnknownClass(
            error => "Could not find $location :\n$@"
        );
    }
}


=pod

=begin classdoc

Method used by the api as entry point for methods calls.
It is convenient for centralizing permmissions checking.

@param method the method name to call
@optional params method call parameters

=end classdoc

=cut

sub methodCall {
    my $self = shift;
    my $class = ref $self;
    my %args = @_;

    my $adm = Administrator->new();

    General::checkParams(args => \%args, required => [ 'method' ], optional => { 'params' => {} });

    # Basically, we allows 'get' only on classes not managed by permissions
    #
    # TODO: For non entity objects, delegate the permissions check on a related entity.
    #       E.g. Permissions on Node should be delegate to ServiceProvider or Host.
    my $method = $args{method};
    if ($args{method} eq 'get' or $self->isa('Entity')) {
        return $self->$method(%{$args{params}});
    }

    my $msg = "Permission denied for <$method> on <$self>";
    throw Kanopya::Exception::Permission::Denied(error => $msg);
}


=pod

=begin classdoc

We define an AUTOLOAD to mimic the DBIx behaviour, it simply calls 'getAttr'
that returns the specified attribute or the relation blessed to a BaseDB object.

@return the value returned by the call of the requested attribute.

=end classdoc

=cut

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $accessor = $autoload[-1];

    return $self->getAttr(name => $accessor);
}


=pod

=begin classdoc

Method called at the object deletion.

=end classdoc

=cut

sub DESTROY {
    my $self = shift;

     # Commented the following block because the exceptions raised
     # by the call $self->save() are strangely not catched by the eval...
#    eval {
#        if ($self->{_altered}) {
#            $self->save();
#        }
#    };
#    if ($@) {
#        my $err = $@;
#        $log->debug("Unable to save <$self> at destroy: $err");
#    }
}

1;
