#    Copyright © 2012-2013 Hedera Technology SAS
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
use Kanopya::Exceptions;
use Kanopya::Database;
use Kanopya::Config;

use Class::ISA;
use Hash::Merge;
use POSIX qw(ceil);
use vars qw($AUTOLOAD);
use Clone qw(clone);

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("basedb");

use Switch;
use TryCatch;
my $err;


# In-memory cache for class types
my $class_type_cache;

# In-memory cache for attributes definitions
my $attr_defs_cache = {};


use constant ATTR_DEF => {
    label => {
        is_virtual  => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        get => {
            description => 'get <object>',
        },
        create => {
            description => 'create a new <object>',
        },
        remove => {
            description => 'remove <object>',
        },
        update => {
            description => 'update <object>',
        },
    };
}

my $merge = Hash::Merge->new('RIGHT_PRECEDENT');


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

    # Extract relation and virtuals for futher handling
    my $virtuals  = $class->_extractVirtuals(hash => $hash);
    my $relations = $class->_extractRelations(hash => $hash);

    # TODO: Probably do the job at _extractRelations
    $class->_populateRelations(relations => $relations,
                               foreign   => 0,
                               attrs     => $hash);

    # Check attributes and build the hierachical attributes hash
    my $attrs = $class->checkAttributes(attrs => $hash);
    # Insert the nex entry into database
    my $self = $class->_dbixNew(attrs => $attrs);

    bless $self, $class;

    # Populate relations and virtuals
    $self->_populateRelations(relations => $relations);
    $self->_populateVirtuals(virtuals => $virtuals);

    return $self;
}


=pod
=begin classdoc

Generic method for object creation.

@return the created object instance

=end classdoc
=cut

sub create {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    return $class->new(%args);
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
    my $class = ref($self) or throw Kanopya::Exception::Method(error => $self);

    General::checkParams(args => \%args, optional => { 'override_relations' => 1 });

    my $override = delete $args{override_relations};
    my $hash = \%args;

    # Extract relation and virtuals for futher handling
    my $virtuals  = $class->_extractVirtuals(hash => $hash);
    my $relations = $class->_extractRelations(hash => $hash);
    delete $hash->{id};

    my $attrs = $class->checkAttributes(attrs => $hash, ignore_missing => 1, group_by => 'module');

    # Update each level of the hierarchy from the lower class to the root class
    my $dbix = $self->_dbix;
    for my $module (reverse sort keys %{ $attrs }) {
        $dbix = $self->_dbixParent(dbix => $dbix, classname => $module->_className);
        $dbix->update(delete $attrs->{$module});
    }

    # Populate relations and virtuals
    $self->_populateRelations(relations => $relations,
                              override  => $override);
    $self->_populateVirtuals(virtuals => $virtuals);

    return $self;
}


=pod
=begin classdoc

Remove records from the entire class hierarchy.

@optional trunc a class name with its hierarchy, allows to delete
          a part of the class hierarchy only.

=end classdoc
=cut

sub delete {
    my ($self, %args) = @_;
    my $class = ref($self) or throw Kanopya::Exception::Method(error => $self);

    General::checkParams(args => \%args, optional => { 'trunc' => undef });

    my $level = $class;
    if (defined $args{trunc}) {
        # Can not truncate to the same class
        if ($args{trunc} eq $class) {
            return $self;
        }
        $level =~ s/^$args{trunc}:://g;
    }

    # Search for top level table in the hierarchy
    my $old  = $self->_dbix;
    my $dbix = $self->_dbixParent(classname => BaseDB->_rootClassName(class => $level));
    if ($args{trunc}) {
        $self->_dbix($self->_dbixParent(dbix => $dbix));
    }

    try {
        $dbix->delete;
    }
    catch (DBIx::Class::Exception $err) {
        # Restore the original dbix
        $self->_dbix($old);

        if ("$err" =~ /a foreign key constraint fails/) {
            (my $msg = "$err") =~ s/.*a foreign key constraint fails//g;
            throw Kanopya::Exception::DB::Cascade(error => "Foreign key constraint fails: $msg");
        }
        else {
            throw Kanopya::Exception::DB(error => "$err");
        }
    }

    return $self;
}


=pod
=begin classdoc

Generic method for object deletion.

=end classdoc
=cut

sub remove {
    my ($self, %args) = @_;
    my $class = ref($self) or throw Kanopya::Exception::Method(error => $self);

    $self->delete();
}


=pod
=begin classdoc

Extend an object instance to a concreter type.

@return the promoted object

=end classdoc
=cut

sub promote {
    my ($class, %args) = @_;
    my $self;

    General::checkParams(args => \%args, required => [ 'promoted' ]);

    my $promoted = delete $args{promoted};
    my $attrs = \%args;

    # Check if the new type is in the same hierarchy
    my $baseclass = ref($promoted);
    if (not ($class =~ m/$baseclass/)) {
        $err = "Unable to promote " . ref($promoted) . " to " . $class;
        throw Kanopya::Exception::Internal::IncorrectParam(error => $err);
    }

    (my $subclass = $class) =~ s/$baseclass\:\://g;
    my $topclassname = BaseDB->_rootClassName(class => $subclass);
    my $topclass = $baseclass . "::" . $topclassname;

    # Set the primary key to the parent primary key value.
    $attrs->{$topclass->_primaryKeyName} = $promoted->id;

    # Extract relation for futher handling
    my $relations = $class->_extractRelations(hash => $attrs);

    # Then extract only the attrs for new tables for insertion
    $attrs = $class->checkAttributes(attrs => $attrs, trunc => $baseclass);
    $self  = $class->_dbixNew(attrs => $attrs, classname => $topclassname);

    bless $self, $class;

    # Populate relations
    $self->_populateRelations(relations => $relations);

    # Set the class type to the new promotion class
    try {
        $self->class_type_id($class->_classTypeId);
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
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

    # Check if the new type is in the same hierarchy
    my $baseclass = ref($args{demoted});
    if (not ($baseclass =~ m/$class/)) {
        $err = "Unable to demote " . ref($args{demoted}) . " to " . $class;
        throw Kanopya::Exception::Internal::IncorrectParam(error => $err);
    }

    # Delete row of tables bellow $class
    $args{demoted}->delete(trunc => $class);

    bless $args{demoted}, $class;

    # Set the class type to the new promotion class
    try {
        $args{demoted}->class_type_id($class->_classTypeId);
    }
    catch (Kanopya::Exception::Internal::NotFound $err) {
        # Unregistred or abstract class name <$class>, assuming it is not an Entity.
    }
    return $args{demoted};
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

    General::checkParams(args => \%args, required => [ 'id' ],
                                         optional => { 'prefetch' => [ ] });

    return $class->find(hash     => { 'me.' . $class->_primaryKeyName => $args{id} },
                        prefetch => $args{prefetch},
                        deep     => 1);
}


=pod
=begin classdoc

Retrieve a value given a name attribute, search this atribute throw the whole class hierarchy.

@param name name of the attribute to get the value

@return the attribute value

=end classdoc
=cut

sub getAttr {
    my ($self, %args) = @_;
    my $class = ref($self) or throw Kanopya::Exception::Method(error => $self);

    General::checkParams(args => \%args, required => [ 'name' ], optional => { 'deep' => 0 });

    # Check if the attribiute exists in attrdef
    my $definition = $class->_attributesDefinition(include_reverse => 1)->{$args{name}};
    if (! defined $definition) {
        throw Kanopya::Exception::Internal::UnknownAttribute(error => "Unknown attribute <$args{name}>");
    }

    # Get the dbix row corresponding to the hierarchy level of the attribute
    my $dbix = $self->_dbixParent(classname => BaseDB->_className(class => $definition->{from_module}));

    # The attribute is a relation, convert the relatiosn dbix to objects
    my $type = $definition->{type};
    if (defined $type && $type eq "relation" && ! $dbix->has_column($args{name})) {
        my $relation = $args{name};
        try {
            my $value = $dbix->$relation;
            switch ($definition->{relation}) {
                case "single" {
                    return (defined $value) ? BaseDB->_dbixBless(dbix => $value, deep => $args{deep}) : undef;
                }
                case /.*multi/ {
                    return map { BaseDB->_dbixBless(dbix => $_, deep => $args{deep}) } $dbix->$relation;
                }
                else {
                    throw Kanopya::Exception(error => "Unknown relation type <$definition->{relation}>");
                }
            }
        }
        catch (Kanopya::Exception $err) {
            $err->rethrow();
        }
        catch ($err) {
            throw Kanopya::Exception::Internal::UnknownAttribute(
                error => "Unable to get value(s) for $definition->{relation} relation <$relation>, $err"
            );
        }
    }
    # The attribute is a virtual, call the corresponding method
    elsif (defined $definition->{is_virtual} && $definition->{is_virtual}) {
        try {
            return $self->_virtualAttribute(name => $args{name});
        }
        catch (Kanopya::Exception $err) {
            $err->rethrow();
        }
        catch ($err) {
            throw Kanopya::Exception::Internal::UnknownAttribute(
                error => "Unable to get value for virtual attribute <$args{name}>, $err"
            );
        }
    }
    # The attribute is regular, get the value from the dbix row
    else {
        try {
            return $dbix->get_column($args{name});
        }
        catch ($err) {
            throw Kanopya::Exception::Internal::UnknownAttribute(
                error => "Unable to get value for attribute <$args{name}> on dbix <$dbix>, $err"
            );
        }
    }
}


=pod
=begin classdoc

Set one name attribute with the given value, search this attribute throw the whole
class hierarchy, and check attribute validity.

@param name the name of the attribute to set the value

@optional value the value to set
@optional save a flag to save the object

@return the value set

=end classdoc
=cut

sub setAttr {
    my ($self, %args) = @_;
    my $class = ref($self) or throw Kanopya::Exception::Method(error => $self);

    General::checkParams(args     => \%args,
                         required => [ 'name' ],
                         optional => { 'value' => undef, 'save' => 0 });

    my ($name, $value) = $self->checkAttr(name => $args{name}, value => $args{value});

    # The attribute is a virtual attribute
    my $definition = $class->_attributesDefinition->{$name};
    if ($definition->{is_virtual}) {
        try {
            $self->_virtualAttribute(name => $name, value => $value);
        }
        catch (Kanopya::Exception $err) {
            $err->rethrow();
        }
        catch ($err) {
            throw Kanopya::Exception::Internal::UnknownAttribute(
                error => "Unable to set value for virtual attribute <$name>, $err"
            );
        }
    }
    # Else set the value on the column
    else {
        my $dbix = $self->_dbixParent(classname => BaseDB->_className(class => $definition->{from_module}));
        try {
            $dbix->set_column($name, $value);
        }
        catch ($err) {
            throw Kanopya::Exception::Internal::UnknownAttribute(
                error => "Unable to set value for attribute <$name> on dbix <$dbix>, $err"
            );
        }
    }
    if ($args{save}) { $self->save(); }

    return $value;
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
                         optional => { 'hash' => {}, 'page' => undef, 'rows' => undef, 'related' => undef,
                                       'join' => undef, 'order_by' => undef, 'dataType' => undef,
                                       'prefetch' => [], 'raw_hash' => {}, 'presets' => {} });

    # Syntax improvement to avoid to call searchRelated
    if (defined $args{related}) {
        my $related = delete $args{related};
        return $class->searchRelated(filters => [ $related ], %args);
    }

    my $merge = Hash::Merge->new('STORAGE_PRECEDENT');

    my $table = $class->_className(class => join('::', $class->_classHierarchy));

    # If the table does not match the class, the conrete table does not exists,
    # so filter on the class type.
    if ($class =~ m/::/ and $class !~ m/::$table$/) {
        $args{hash}->{'class_type.class_type'} = $class;
    }

    my $prefetch = $class->_joinHierarchy;
    $prefetch = $merge->merge($prefetch, $args{join});

    for my $relation (@{ $args{prefetch} }) {
        my @comps = split(/\./, $relation);
        while (scalar @comps) {
            my $join_query = $class->_joinQuery(comps => \@comps, indepth => 1);
            $prefetch = $merge->merge($prefetch, $join_query->{join});
            $args{hash} = $merge->merge($args{hash}, $join_query->{where});
            pop @comps;
        }
    }

    my $virtuals = {};
    my $attrdefs = $class->_attributesDefinition;

    FILTER:
    for my $filter (keys %{ $args{hash} }) {
        # If the attr is virtual, move the filter to the virtuals hash
        if ($attrdefs->{$filter}->{is_virtual}) {
            $virtuals->{$filter} = delete $args{hash}->{$filter};
            next FILTER;
        }
        next FILTER if substr($filter, 0, 3) eq "me.";

        my @comps = split('\.', $filter);
        my $value = $args{hash}->{$filter};

        if (scalar (@comps) > 1) {
            my $value = $args{hash}->{$filter};
            my $attr = pop @comps;

            delete $args{hash}->{$filter};

            my $join_query = $class->_joinQuery(comps => \@comps);
            $prefetch = $merge->merge($prefetch, $join_query->{join});
            $args{hash}->{$comps[-1] . '.' . $attr} = $value;
            $args{hash} = $merge->merge($args{hash}, $join_query->{where});
        }
    }

    my $virtual_order_by;
    if (defined $args{order_by}) {
        # TODO: handle multiple order_by
        my @orders = split(/ /, $args{order_by});
        $args{order_by} = '';

        ORDER:
        for my $order (@orders) {
            if (lc($order) =~ m/asc|desc/) {
                if (defined $virtual_order_by) {
                    $virtual_order_by .= ' ' . $order;
                }
                else {
                    $args{order_by} .= ' ' . $order;
                }
            }
            else {
                if ($attrdefs->{$order}->{is_virtual}) {
                    $virtual_order_by = $order;
                }
                else {
                    $args{order_by} .= ' ' . $order;
                }
            }
        }
    } elsif ($args{page}) {
        $args{order_by} = "me." . $class->_primaryKeyName;
    }

    $args{hash} = $merge->merge($args{hash}, $args{raw_hash});
    my $rs = $class->_dbixSearch(class => $table,      hash     => $args{hash},
                                 page  => $args{page}, prefetch => $prefetch,
                                 rows  => $args{rows}, order_by => $args{order_by},
                                 join  => $args{join});

    # Instanciate Kanopya classes from DBIx result set
    try {
        while (my $row = $rs->next) {
            my $obj = { _dbix => $row };

            my $root = BaseDB->_dbixRoot(dbix => $row);
            if ($root->has_column("class_type_id") and not ($class =~ m/^ClassType.*/)) {
                my $class_type = $class->_classType(id => $root->get_column("class_type_id"));

                if (length($class_type) > length($class)) {
                    General::requireClass($class_type);
                    $obj = $class_type->get(id => $root->get_column("entity_id"));
                }
                else {
                    bless $obj, $class_type;
                }
            }
            else {
                bless $obj, $class;
            }

            push @objs, $obj;
        }
    }
    catch (Kanopya::Exception $err) {
        $err->rethrow();
    }
    catch ($err) {
        throw Kanopya::Exception::Internal(error => "$err");
    }

    # Finally filter on virtual attributes if required
    for my $virtual (keys %{ $virtuals }) {
        my $op = '=';
        if (ref($virtuals->{$virtual}) eq "HASH") {
            map { $op = $_; $virtuals->{$virtual} = $virtuals->{$virtual}->{$_} }
                keys %{ $virtuals->{$virtual} };
        }
        @objs = grep { General::compareScalars(left_op  => $_->$virtual,
                                               right_op => $virtuals->{$virtual},
                                               op       => $op) } @objs;
    }

    # Sort by virtual attribute if required
    if ($virtual_order_by) {
        my ($attribute, $order) = split(/ /, $virtual_order_by);
        if (defined $order and lc($order) eq 'desc') {
            @objs = sort { $b->$attribute <=> $a->$attribute } @objs;
        }
        else {
            @objs = sort { $a->$attribute <=> $b->$attribute } @objs;
        }
    }

    if (defined ($args{dataType}) and $args{dataType} eq "hash") {
        my $total = (defined $args{page} or defined $args{rows}) ? $rs->pager->total_entries : $rs->count;

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

    General::checkParams(args => \%args, required => [ 'filters' ], optional => { 'hash' => {} });

    my $join;
    try {
        # If the function is called on a class that is only a base class of the
        # class the relation is on (for example 'virtual_machines' on a Host),
        # return a more understandable error message
        $join = $class->_joinQuery(comps => $args{filters}, reverse => 1);
    }
    catch ($err) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "Could not find a relation " . join('.', @{ $args{filters} }) . " on $self"
              );
    }

    my $merge = Hash::Merge->new('STORAGE_PRECEDENT');
    $args{hash} = $merge->merge($args{hash}, $join->{where});

    my $searched_class = BaseDB->_dbixClass(schema => $join->{source});
    General::requireClass($searched_class);

    my $method = $join->{accessor} eq "single" ? "find" : "search";
    return $searched_class->$method(%args,
               raw_hash => { $join->{on} => ref ($self) ? $self->id : $args{id} },
               hash     => $args{hash},
               join     => $join->{join}
           );
}


=pod
=begin classdoc

Return a single element matching the specified criterias take the same arguments as 'search'.

@return the matching object

=end classdoc
=cut

sub find {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, optional => { 'hash' => {}, 'deep' => 0 });

    my @objects = $class->search(rows => 1, %args);

    my $object = shift @objects;
    if (! defined $object) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "No entry found for " . $class . ", with hash " . Dumper($args{hash})
              );
    }
    return $object;
}


=pod
=begin classdoc

Return a single element matching the specified criterias take the same arguments as 'searchRelated'.

@return the matching object

=end classdoc
=cut

sub findRelated {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'filters' ],
                         optional => { 'hash' => { } });

    my @objects = $class->searchRelated(%args);

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

Return the object that matches the criterias
or creates it if it doesn't exist

@param args the criterias

@return the object found or created
=cut

sub findOrCreate {
    my ($class, %args) = @_;

    try {
        return $class->find(hash => \%args);
    }
    catch ($err) {
        return $class->create(%args);
    }
}


=pod
=begin classdoc

Return a single element matching the specified criterias take the same arguments as 'search'.

@return the matching object

=end classdoc
=cut

sub save {
    my ($self) = @_;
    my $dbix = $self->_dbix;

    try {
        while (defined $dbix) {
            $dbix->update;
            $dbix = $self->_dbixParent(dbix => $dbix);
        }
    }
    catch ($err) {
        throw Kanopya::Exception::DB(error => "$err");
    }

    return $self;
}


=pod
=begin classdoc

Return the object as a hash so that it can be safely be converted to JSON.
Should be named differently but hey...
If called on the class, return the object description instead of attributes values

@optional no_relations force to remove the relations from the atrribute definition

@return the hash representing the object or the model

=end classdoc
=cut

sub toJSON {
    my ($self, %args) = @_;
    my $class = ref ($self) || $self;

    General::checkParams(args     => \%args,
                         optional => { 'no_relations' => 0, 'raw' => 0, 'primaries' => 1,
                                       'virtuals' => 1, 'expand' => [], 'deep' => 0 });

    # Firstly browse the attrdef and get definitions / values
    my $output = {};
    my $attributes = $class->_attributesDefinition(group_by => 'module');
    foreach my $module (keys %{ $attributes }) {
        foreach my $attr (keys %{ $attributes->{$module} }) {
            my $definition = $attributes->{$module}->{$attr};

            # Skip virtuals if raw output required
            next if ($args{raw} && $definition->{is_virtual});

            # I called on instance, get the value of the attributes
            if (ref($self)) {
                my $type = defined $definition->{type} ? $definition->{type} : '';

                # Filter in function of options, keep the single relation ids only
                if (($args{virtuals} || ! $definition->{is_virtual}) &&
                    ($args{primaries} || ! $definition->{is_primary}) &&
                    ($type ne 'relation' || $definition->{is_foreign_key})) {
                    # Set the value of the attribute
                    $output->{$attr} = $self->getAttr(name => $attr);
                }
            }
            # I called on the class, keep the attribute definition
            else {
                # Filter primary keys except the lower class one
                if (! ($definition->{is_primary} && "$module" ne "$class")) {
                    $output->{attributes}->{$attr} = $definition;
                }
            }
        }
    }

    # I called on instance, complete the output vith optional additinal values
    if (ref($self)) {
        if (! $args{raw}) {
            $output->{pk} = $self->id;
        }

        # If some expands requested, get the corresponding relations json values
        if ($args{expand}) {
            # Build the expands hash
            my $expands;
            if (ref($args{expand}) and ref($args{expand}) eq "HASH") {
                $expands = $args{expand};
            }
            else {
                $expands = {};
                for my $expand (@{ $args{expand} }) {
                    my $current = $expands;
                    my @comps   = split(/\./, $expand);
                    for my $comp (@comps) {
                        if (not defined $current->{$comp}) {
                            $current->{$comp} = {};
                        }
                        $current = $current->{$comp};
                    }
                }
            }

            # Browse the relations to get values
            for my $expand (keys %$expands) {
                my $obj  = $self;
                my $dbix = $self->_dbix;
                my $is_relation = 0;

                COMPONENT:
                while ($expand && $dbix) {
                    my $source = $dbix->result_source;
                    my $many_to_many = $source->result_class->can("_m2m_metadata") &&
                                           defined ($source->result_class->_m2m_metadata->{$expand});

                    if ($source->has_relationship($expand)) {
                        $is_relation = $source->relationship_info($expand)->{attrs}->{accessor};
                        last COMPONENT;
                    }
                    elsif ($many_to_many) {
                        $is_relation = "multi";
                        last COMPONENT;
                    }
                    $dbix = $self->_dbixParent(dbix => $dbix);
                }

                if ($is_relation) {
                    $output->{$expand} = [];
                    if ($is_relation eq 'single_multi' || $is_relation eq 'multi') {
                        for my $item ($obj->getAttr(name => $expand, deep => $args{deep})) {
                            push @{$output->{$expand}}, $item->toJSON(expand => $expands->{$expand},
                                                                      deep   => $args{deep});
                        }
                    }
                    elsif ($is_relation eq 'single') {
                        my $obj = $self->getAttr(name => $expand, deep => 1);
                        if ($obj) {
                            $output->{$expand} = $obj->toJSON(expand => $expands->{$expand},
                                                              deep   => $args{deep});
                        }
                    }
                }
           }
        }
    }
    # If called on the class, complete the json output with relations and methods definitions
    else {
        my @hierarchy = $class->_classHierarchy;
        my $depth = scalar @hierarchy;
        my $current = $depth;
        my $parent;

        for (my $current = $depth - 1; $current >= 0; $current--) {
            $parent = Kanopya::Database::schema->source($hierarchy[$current]);
            my @relnames = $parent->relationships();
            for my $relname (@relnames) {
                my $relinfo = $parent->relationship_info($relname);

                if (scalar (grep { $_ eq (split('::', $relinfo->{source}))[-1] } @hierarchy) == 0 and
                    $relinfo->{attrs}->{is_foreign_key_constraint} or
                    $relinfo->{attrs}->{accessor} eq "multi") {

                    my $resource = lc((split("::", $relinfo->{class}))[-1]);
                    $resource =~ s/_//g;

                    $output->{relations}->{$relname} = $relinfo;
                    $output->{relations}->{$relname}->{from} = $hierarchy[$current];
                    $output->{relations}->{$relname}->{resource} = $resource;

                    # We must have relation attrs within attrdef to keep
                    # informations as label, is_editable and is_mandatory.
                    # Except if we explicitly don't want it (no_relations option)

                    if ($args{no_relations}) {
                        delete $output->{attributes}->{$relname . "_id"};
                    }
                }
            }
            pop @hierarchy;
        }
        $output->{methods} = $self->_methodsDefinition;
        $output->{pk} = {
            pattern      => '^\d*$',
            is_mandatory => 1,
        };
    }
    return $output;
}


=pod
=begin classdoc

Get the primary key of the object

@return the primary key value

=end classdoc
=cut

sub id {
    my ($self, %args) = @_;
    my $class = ref($self) or throw Kanopya::Exception::Method(error => $self);

    return $self->_dbix->get_column($self->_primaryKeyName);
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

Default label management
Label is the value of the attr returned by _labelAttr or the object id
Subclass can redefined this method to return specific label

@return the label string for this object

=end classdoc
=cut

sub label {
    my $self = shift;

    my $label = $self->_labelAttr;
    return $label ? $self->$label : $self->id;
}


=pod
=begin classdoc

Check attributes validity in the class hierarchy and build as the same time
a hashref structure to use for database inserts/updates.

@param attrs hash containing keys/values of attributes to check
@optional trunc a class name with its hierarchy, allows to return
          a sub hash exluding attributes of classes in this hierarchy.

@return the hash of keys/values of attributes of each module in the class hierarchy,
        sorted by table name.

=end classdoc
=cut

sub checkAttributes {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args    => \%args,
                         required => [ 'attrs' ],
                         optional => { 'trunc'          => undef,
                                       'group_by'       => 'hierarchy',
                                       'ignore_missing' => 0 });

    # Get the full attribute defintion of the class hierarchy
    my $attrdef = $class->_attributesDefinition(trunc => $args{trunc});

    # Browse all attributes given in parameters
    my $by_module = {};
    for my $attribute (keys %{ $args{attrs} }) {
        # Check the attribute value
        my ($name, $value) = $self->checkAttr(name => $attribute, value => $args{attrs}->{$attribute});

        # Remove the current attribute to deduce not given ones
        my $definition = delete $attrdef->{$name};

        # Finally add the key/value to the processed attributes
        $by_module->{$definition->{from_module}}->{$name} = $value;
    }

    # Search for default values for remaining mandatory attributes
    for my $mandatory (grep { $attrdef->{$_}->{is_mandatory} } keys %{ $attrdef }) {
        if (defined $attrdef->{$mandatory}->{default}) {
            $by_module->{$attrdef->{$mandatory}->{from_module}}->{$mandatory}
                = $attrdef->{$mandatory}->{default};
        }
        elsif (! $args{ignore_missing}) {
            throw Kanopya::Exception::Internal::IncorrectParam(
                      error => "Missing mandatory attribute <$mandatory>"
                  );
        }
    }

    # Format the output in function of the group_by parameter
    my $output;
    if ($args{group_by} eq 'hierarchy') {
        # Deduce the target table level to return
        my $target;
        if (defined $args{trunc}) {
            (my $truncated = $class) =~ s/^$args{trunc}\:\://g;
            $target = BaseDB->_tableName(classname => BaseDB->_rootClassName(class => $truncated));
        }
        else {
            $target = $class->_rootTableName;
        }

        # Build the hierarchy hash, and keep the target table level to return
        my $current = {};
        for my $level ($class->_classHierarchy) {
            my $table = BaseDB->_tableName(classname => $level);

            # Set the proper attrs to the current level if exists, update the current pointer
            my @modules = grep { $_ =~ m/(^|::)$level$/ } keys %{ $by_module };
            $current = $current->{$table} = (scalar @modules) ? $by_module->{shift @modules} : {};

            # Keep the level corresponding to truncate table for result
            if ($target eq $table) {
                $output = $current;
            }
        }
    }
    else {
        $output = $by_module;
    }
    return $output;
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

    General::checkParams(args => \%args, required => [ 'name' ], optional => { 'value' => undef });

    # Check if the attribiute exists in attrdef
    my $definition = $class->_attributesDefinition->{$args{name}};
    if (! defined $definition) {
        throw Kanopya::Exception::Internal::IncorrectParam(error => "Unknown attribute <$args{name}>");
    }

    # If the attr is a single relation with a value as object,
    # use the id of the object to set the id attribute corresponding to the relation
    if ((defined $definition->{relation} && defined $class->_attributesDefinition->{$args{name} . '_id'}) &&
        (defined($args{value}) && ref($args{value}) && $args{value}->isa('BaseDB'))) {

        # Replace the attribute by the coresponding key of the relation
        $args{name} = $args{name} . '_id';

        # Use the id the related object as value
        $args{value} = $args{value}->id;

        $definition = $class->_attributesDefinition->{$args{name}};
    }

    # If exists, check the value.
    if (! defined $args{value} && $definition->{is_mandatory}) {
        throw Kanopya::Exception::Internal::WrongValue(
                  error => "Undefined value for mandatory attribute <$args{name}>"
              );
    }
    elsif ((defined $args{value}) && (defined $definition->{pattern}) &&
           ($args{value} !~ m/($definition->{pattern})/)) {
        throw Kanopya::Exception::Internal::WrongValue(
                  error => "Wrong value <$args{value}> for attribute <$args{name}>"
              );
    }

    return ($args{name}, $args{value});
}


=pod
=begin classdoc

Method used by the api as entry point for methods calls.
It is convenient for centralizing permmissions checking.

@param method the method name to call
@optional params method call parameters

=end classdoc
=cut

sub apiCall {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'method' ],
                                         optional => { 'params' => {} });

    my $userid   = Kanopya::Database::user->{user_id};
    my $usertype = Kanopya::Database::user->{user_system};
    my $godmode  = defined Kanopya::Database::config->{god_mode} &&
                       Kanopya::Database::config->{god_mode} eq 1;

    if (not ($godmode || $usertype)) {
        $self->checkUserPerm(user_id => $userid, %args);
    }

    my $method = $args{method};
    return $self->$method(%{ $args{params} });
}


=pod
=begin classdoc

Check permmissions on a method for a user.

=end classdoc
=cut

sub checkUserPerm {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'method', 'user_id' ],
                                         optional => { 'params' => {} });

    # For the class method get, intanciate the specified object from the id,
    # and delegate the permissions on get method to the object himself.
    if (!ref($self) && $args{method} eq 'get' && defined $args{params}->{id}) {
        return $class->get(id => $args{params}->{id})->checkUserPerm(%args);
    }

    # For delegated CRUD, check permission for 'update' on the delagated object
    my $delegateeattr = $class->_delegateeAttr;
    if (defined $delegateeattr && $args{method} =~ m/^(get|create|update|remove)$/) {
        (my $delegateerel = $delegateeattr) =~ s/_id$//g;

        # If the method is 'create', or 'update' with the delegatee attr sepcified,
        # instanciate the delegatee from the delegatee attr param
        my $delegatee;
        if ($args{method} =~ m/^(create|update)$/ && defined $args{params}->{$delegateeattr}) {
            # Retreive the relation class to instanciate it
            my $delegateeclass = $self->_relationshipInfos(relation => $delegateerel)->{class};
            $delegatee = $delegateeclass->get(id => $args{params}->{$delegateeattr});
        }
        # Else get the delegatee object from the instance
        else {
            $delegatee = $self->$delegateerel;
        }

        # Check the permission for update on the delagatee object
        try {
            $delegatee->checkUserPerm(user_id => $args{user_id}, method => "update");
        }
        catch (Kanopya::Exception::Permission::Denied $err) {
            my $msg = $self->_permissionDeniedMessage(method => $args{method}) . " from " .
                      $delegatee->_className . " <" . $delegatee->label . ">";
            throw Kanopya::Exception::Permission::Denied(error => $msg);
        }

        # Also check the permisions on the object himself if the other rights than CRUD are not delegated
        $delegatee = undef;
        eval {
            $delegatee = $self->_delegatee;
        };
        if (! (ref($self) && ref($delegatee) eq ref($self))) {
            return;
        }
    }

    # Firstly check permssions on parameters
    foreach my $key (keys %{ $args{params} }) {
        my $param = $args{params}->{$key};
        if ((ref $param) eq "HASH" && defined ($param->{pk}) && defined ($param->{class_type_id})) {
            my $paramclass = $self->_classType(id => $param->{class_type_id});
            try {
                $paramclass->_delegatee->checkPerm(user_id => $args{user_id}, method => "get");
            }
            catch (Kanopya::Exception::Permission::Denied $err) {
                my $msg = "Permission denied to get parameter " . $param->{pk};
                throw Kanopya::Exception::Permission::Denied(error => $msg);
            }

            # TODO: use DBIx::Class::ResultSet->new_result and bless it to 'class' instead of a 'get'
            $args{params}->{$key} = $paramclass->get(id => $param->{pk});
        }
    }

    $log->debug("Check permission for user <" . $args{user_id} . "> on <" . $self->_delegatee .
                "> to <$args{method}>");

    # Check the permissions for the logged user
    try {
        $self->_delegatee->checkPerm(user_id => $args{user_id}, method => $args{method});
    }
    catch ($err) {
        throw Kanopya::Exception::Permission::Denied(
                  error => $self->_permissionDeniedMessage(method => $args{method})
              );
    }
}


=pod
=begin classdoc

Propagate object specific permissions on a related object. This
method is called at creation of related objects that have tagged
the relation that link to this one as 'is_delegatee'.

@param related the related object on which propagate permissions.

=end classdoc
=cut

sub propagatePermissions {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'related' ]);
}


=pod
=begin classdoc

Return a hash ref containing all ATTR_DEF for each class in the hierarchy.
Retunr the cached copy of exists, store the result in cache instead.

@optional group_by outpout hash format policy (module|none)

@return the attributes defintion of the full hierarchy of the class

=end classdoc
=cut

sub _attributesDefinition {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args     => \%args,
                         optional => { 'group_by' => 'none', 'trunc' => undef, 'include_reverse' => 0 });

    # Build th key to identify the requested output whitin the cache
    my $cachekey = $class;
    map { $cachekey .= ';' . $_ . ':' . ((defined $args{$_}) ? $args{$_} : '') } keys %args;

    # Return the cached copy of the attributes definition if exists
    if (exists $attr_defs_cache->{$cachekey}) {
        return clone($attr_defs_cache->{$cachekey});
    }

    my $attributedefs = {};
    my@hierarchy = split('::', $class);
    while (@hierarchy) {
        my $schema;
        my $modulename = join('::', @hierarchy);

        # Ignore modules not in truncated hierarchy
        if (defined $args{trunc} && $modulename !~ m/^$args{trunc}\:\:/) {
            pop @hierarchy;
            next;
        }

        try {
            # Required the current module
            General::requireClass($modulename);

            # Get the corresponding result source if exists (ignore_holes => 0)
            $schema = $modulename->_resultSource(ignore_holes => 0);
        }
        catch (Kanopya::Exception::Internal::UnknownClass $err) {
            # Ignore holes in the class hierarchy
            pop @hierarchy;
            next;
        }
        catch (Kanopya::Exception::DB::UnknownSource $err) {
            # Ignore holes in the table hierarchy
            pop @hierarchy;
            next;
        }
        catch ($err) {
            # Let's throw compilation errors...
            $err->rethrow();
        }

        # Get the attribute definition for the current level of the hierarchy
        $attributedefs->{$modulename} = clone($modulename->getAttrDef());

        # For each regular attributes, add a generic definition if not exists in attrdef
        for my $column (grep { ! defined ($attributedefs->{$modulename}->{$_}) } $schema->columns) {
            $attributedefs->{$modulename}->{$column} = {
                pattern      => '^.*$',
                is_mandatory => 0,
            };
        }
        for my $primary (@{ $schema->_primaries }) {
            $attributedefs->{$modulename}->{$primary}->{is_primary} = 1;
        }
        for my $unique_constraint (values %{ $schema->_unique_constraints }) {
            for my $unique (@{ $unique_constraint }) {
                $attributedefs->{$modulename}->{$unique}->{is_unique} = 1;
            }
        }

        my $pkname;
        try {
            $pkname = $class->_primaryKeyName(schema => $schema, allow_multiple => 0);
        }
        catch (Kanopya::Exception::Internal $err) {
            # Relation tables have multiple primary key
            $pkname = "";
        }

        # Complete the attrdef with many to many relations
        my $multi = {};
        if ($schema->result_class->can("_m2m_metadata")) {
            for my $manytomany (values %{ $schema->result_class->_m2m_metadata }) {
                $multi->{$manytomany->{relation}} = $manytomany;
                $attributedefs->{$modulename}->{$manytomany->{accessor}} = {
                    type         => "relation",
                    relation     => "single_multi",
                    is_mandatory => 0,
                };
            }
        }

        # Complete the attrdef with regular relations, expecting inheritance and many to many
        for my $relation ($schema->relationships) {
            my $relinfo = $schema->relationship_info($relation);

            # Deduce the key and fk of the relation from definition
            (my $key = (keys %{ $relinfo->{cond} })[0]) =~ s/.*foreign\.//g;
            (my $fk = (values %{ $relinfo->{cond} })[0]) =~ s/.*self\.//g;

            if (($fk ne $pkname || (($fk eq $key || $args{include_reverse}) &&
                (! $relinfo->{attrs}->{is_foreign_key_constraint}))) &&
                (! $relinfo->{attrs}->{cascade_update} || $key eq $pkname)) {
                if (! defined $attributedefs->{$modulename}->{$relation}) {
                    $attributedefs->{$modulename}->{$relation} = {};
                }

                $attributedefs->{$modulename}->{$relation}->{type} = "relation";
                $attributedefs->{$modulename}->{$relation}->{is_mandatory} = 0;
                if ($relinfo->{attrs}->{accessor} eq "multi" && ! defined $multi->{$relation}) {
                    $attributedefs->{$modulename}->{$relation}->{relation} = "single_multi";
                }
                else {
                    $attributedefs->{$modulename}->{$relation}->{relation} = $relinfo->{attrs}->{accessor};
                    if (defined $multi->{$relation}) {
                        $attributedefs->{$modulename}->{$relation}->{link_to}
                            = $multi->{$relation}->{foreign_relation};
                    }
                }

                # Tag the corresponding id attribute as foreign key
                if ($relinfo->{attrs}->{is_foreign_key_constraint}) {
                    $attributedefs->{$modulename}->{$relation . "_id"}->{is_foreign_key} = 1;
                }
            }
        }
        pop @hierarchy;
    }

    # Add the BaseDB attrs to the upper class attrs
    $attributedefs->{$class->_rootClassName}
        = $merge->merge($attributedefs->{$class->_rootClassName}, clone(BaseDB::getAttrDef()));

    if ($args{group_by} eq 'module') {
        $attr_defs_cache->{$cachekey} = $attributedefs;
        return clone($attributedefs);
    }

    # Finally merge all module attrs into one level hash
    my $result = {};
    for my $module (sort keys %$attributedefs) {
        # Keep the module belonging for each attributes
        for my $attrname (keys %{ $attributedefs->{$module} }) {
            my $definition = $attributedefs->{$module}->{$attrname};
            if (! (defined $result->{$attrname} && defined $definition->{specialized})) {
                $definition->{from_module} = $module;
            }
        }
        # Merge in the flat attribute definition
        $result = $merge->merge($result, $attributedefs->{$module});
    }
    $attr_defs_cache->{$cachekey} = $result;
    return clone($result);
}


=pod
=begin classdoc

Build the full list of methods by concatenating methods hash of each classes
in the hierarchy, it also support miulti inherintance by using Class::ISA::self_and_super_path.

@return the hash of methods exported to the api for this class.

=end classdoc
=cut

sub _methodsDefinition {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'depth' => undef });

    my $methods = {};
    my @supers  = Class::ISA::self_and_super_path($class);
    my $merge   = Hash::Merge->new();

    if (not defined $args{depth}) {
        $args{depth} = scalar @supers;
    }
    elsif ($args{depth} < 0) {
        $args{depth} = (scalar @supers) + $args{depth};
    }

    SUPER:
    for my $sup (@supers) {
        if ($sup->can('methods')) {
            $methods = $merge->merge($methods, $sup->methods());
        }
        last SUPER if --$args{depth} == 0;
     }
     return $methods;
}


=pod
=begin classdoc

Extract relations sub hashes from the hash represeting the object.

@param hash hash representing the object.

@return the original hash containing the relations sub hashes only

=end classdoc
=cut

sub _extractRelations {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'hash' ]);

    # Extrating relation from attrs
    my $relations = {};
    for my $attr (keys %{$args{hash}}) {
        if (ref($args{hash}->{$attr}) =~ m/ARRAY|HASH/) {
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
@param foreign boolean to indicate the relations the create
       A value of '0' means we need to create the entities that have a foreign key to 'self'
       A value of '1' means we need to create the entities that 'self' points to

=end classdoc
=cut

sub _populateRelations {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'relations' ],
                         optional => { 'override' => 0, 'foreign' => 1, 'attrs' => undef });

    # For each relations type
    RELATION:
    for my $relation (keys %{ $args{relations} }) {
        my $rel_infos = $self->_relationshipInfos(relation => $relation);
        if (($args{foreign} == 0 && $rel_infos->{relation} ne "single") ||
            ($args{override} == 0 && $args{foreign} == 1 && $rel_infos->{relation} eq "single")) {
            next RELATION;
        }

        my $relation_class = $rel_infos->{class};
        my $relation_schema = $rel_infos->{schema};
        my $key = $rel_infos->{linkfk} || "id";

        # For single relations, create or update the related instance
        if (defined $rel_infos->{relation} && $rel_infos->{relation} eq "single") {
            my $entry = $args{relations}->{$relation};
            if (ref($self) && $self->$relation) {
                # We have the relation id, it is a relation update
                $self->$relation->update(%$entry, override => $args{override});
            }
            else {
                # Id do not exists, it is a relation creation
                my $obj = $relation_class->create(%$entry);
                $args{attrs}->{$obj->_primaryKeyName} = $obj->id;
            }
        }
        # For multi relations, create/update/remove the related instances in funtion
        # of existing entries.
        else {
            my $existing = {};
            my @entries = $self->searchRelated(filters => [ $relation ]);
            %$existing = map { $_->$key => $_ } @entries;

            # Create/update all entries
            for my $entry (@{ $args{relations}->{$relation} }) {
                if (defined $rel_infos->{relation} && $rel_infos->{relation} eq 'single_multi') {
                    my $id = delete $entry->{@{$relation_schema->_primaries}[0]};
                    if ($id) {
                        # We have the relation id, it is a relation update
                        $relation_class->get(id => $id)->update(%$entry);
                        delete $existing->{$id};
                    }
                    else {
                        # Create the new relationships
                        $entry->{$rel_infos->{fk}} = $self->id;
                        # Id do not exists, it is a relation creation
                        $relation_class->create(%$entry);
                    }
                }
                elsif (defined $rel_infos->{relation} && $rel_infos->{relation} eq 'multi') {
                    # If instances are given in parameters instead of ids, use the ids
                    if (ref($entry)) {
                        $entry = $entry->id;
                    }

                    my $exists = delete $existing->{$entry};
                    if (not $exists) {
                        # Create entries in the link table
                        $relation_class->create($rel_infos->{fk}     => $self->id,
                                                $rel_infos->{linkfk} => $entry);
                    }
                }
            }

            # Finally delete remaining entries
            if ($args{override}) {
                for my $remaining (values %$existing) {
                    $remaining->remove();
                }
            }
        }
    }
}

=pod
=begin classdoc

Extract virtual attributes the hash represeting the object.

@param hash hash representing the object.

@return the original hash containing the editable virtual attributes only

=end classdoc
=cut

sub _extractVirtuals {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'hash' ]);

    my $attrdef = $class->_attributesDefinition;

    # Remove virtual attributes keys/values
    my $virtuals = {};
    for my $attribute (keys %{ $args{hash} }) {
        if ($attrdef->{$attribute}->{is_virtual}) {
            if ($attrdef->{$attribute}->{is_editable}) {
                $virtuals->{$attribute} = $args{hash}->{$attribute};
            }
            delete $args{hash}->{$attribute};
        }
    }
    return $virtuals;
}


=pod
=begin classdoc

For each vitual editable attribute, call the corresponding setter method.

@param virtuals hash containing virtual attributes keys/values.

=end classdoc
=cut

sub _populateVirtuals {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'virtuals' ]);

    # Use the corresponding setter method for virtual attributes
    for my $virtual (keys %{ $args{virtuals} }) {
        $self->_virtualAttribute(name => $virtual, value => $args{virtuals}->{$virtual});
    }
}


=pod
=begin classdoc

Get/Set a virtual attribute. Search for a method that have the same name
than the virtual attribute, try the camel case name also.

@param name the name of the virtual attribute
@param value the value to set

=end classdoc
=cut

sub _virtualAttribute {
    my ($self, %args) = @_;
    my $class = ref($self) or throw Kanopya::Exception::Method(error => $self);

    General::checkParams(args => \%args, required => [ 'name' ], optional => { 'value' => undef });

    # Try to find setter/getter method with name or camel-case name
    my $name = $args{name};
    if (! $self->can($name)) {
        $name = General::normalizeMethod($name);
        if (! $self->can($name)) {
            throw Kanopya::Exception::Internal(
                      error => "Can not find setter/getter method for virtual attribute <$args{name}>");
        }
    }
    # Get of set the virtual attribute in fucntion of value argument
    if (defined $args{value}) {
        return $self->$name($args{value});
    }
    else {
        return $self->$name();
    }
}


=pod
=begin classdoc

Gather informations about a relationship in a more convenient formalism than the dbix one.

@return the relationship infos

=end classdoc
=cut

sub _relationshipInfos {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'relation' ]);

    my $attrdef = $class->_attributesDefinition->{$args{relation}};
    my $module = $attrdef->{from_module};
    my $schema = $module->_resultSource;

    # Get the schema of the relation
    my $relation_schema;
    try {
        if (defined $attrdef->{specialized}) {
            $relation_schema = Kanopya::Database::schema->source($attrdef->{specialized});
        }
        else {
            $relation_schema = $schema->related_source($args{relation});
        }
    }
    catch ($err) {
        throw Kanopya::Exception::Internal::NotFound(error => "$err");
    }

    # Get the class from dbix
    my $relation_class = BaseDB->_dbixClass(schema => $relation_schema);

    # Deduce the fk from relation definition
    my @conds = keys %{ $schema->relationship_info($args{relation})->{cond} };
    (my $fk = $conds[0]) =~ s/.*foreign\.//g;

    my $infos = {
        class    => $relation_class,
        schema   => $relation_schema,
        fk       => $fk,
        relation => $attrdef->{relation}
    };

    if (defined $attrdef->{relation} && $attrdef->{relation} eq 'multi') {
        # Deduce the foreign key attr for link entries in relations multi
        my $linked_reldef = $relation_schema->relationship_info($attrdef->{link_to});
        my @conds = values %{$linked_reldef->{cond}};

        # Deduce the reverse key from relation definition
        ($infos->{linkfk} = $conds[0]) =~ s/.*self\.//g;
    }

    return $infos;
}


=pod
=begin classdoc

Build the join query required to get all the attributes of the whole class hierarchy.

@return the join query

=end classdoc
=cut

sub _joinHierarchy {
    my ($class) = @_;

    # Get the hierachy and remove the top level class
    my @hierarchy = $class->_classHierarchy;
    shift @hierarchy;

    my $join = {};
    for my $level (@hierarchy) {
        my $parent = $class->_parentRelationName(schema => BaseDB->_resultSource(classname => $level));
        $join = { $parent => $join };
    }
    return $join;
}


=pod
=begin classdoc

Build the JOIN query to get the attributes of a multi level depth relationship.

@return the join query

=end classdoc
=cut

sub _joinQuery {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'comps' ],
                         optional => { 'reverse' => 0, 'indepth' => 0 });

    my @comps = @{ $args{comps} };
    my $source = $class->_resultSource;
    my $on = "";
    my $relation;
    my $where = {};
    my $accessor = "single";

    my @joins;
    my $i = 0;
    try {
        COMP:
        while ($i < scalar @comps) {
            my $comp = $comps[$i];
            my $many_to_many = $source->result_class->can("_m2m_metadata") &&
                               defined ($source->result_class->_m2m_metadata->{$comp});
            my @segment = ();

            M2M:
            while (! $source->has_relationship($comp) && ! $many_to_many) {
                my $parent = $class->_parentRelationName(schema => $source);
                if ($args{reverse}) {
                    $relation = $source->reverse_relationship_info($parent);
                    @segment = ((keys %$relation)[0], @segment);
                }
                else {
                    @segment = (@segment, $parent);
                }
                last M2M if ! (defined $parent && $source->has_relationship($parent));
                $source = $source->related_source($parent);
                $many_to_many = $source->result_class->can("_m2m_metadata") &&
                                defined ($source->result_class->_m2m_metadata->{$comp});
            }

            if ($source->result_class->can("_m2m_metadata") &&
                defined ($source->result_class->_m2m_metadata->{$comp})) {
                splice @comps, $i, 1, ($source->result_class->_m2m_metadata->{$comp}->{relation},
                                       $source->result_class->_m2m_metadata->{$comp}->{foreign_relation});
                @joins = (@joins, @segment);
                next COMP;
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

            $relation = $source->relationship_info($comp);
            if ($relation->{attrs}->{accessor} eq "multi") {
                $accessor = "multi";
            }

            $where  = $relation->{attrs}->{where};
            $source = $source->related_source($comp);
            $i += 1;
        }
    }
    catch ($err) {
        throw Kanopya::Exception::Internal(error => "$err");
    }

    # Get all the hierarchy of the relation
    my @indepth;
    if ($args{indepth}) {
        my $depth_source = $source;
        my $parent = $class->_parentRelationName(schema => $depth_source);
        while (defined $parent && $depth_source->has_relationship($parent)) {
            @indepth = ($parent, @indepth);
            $depth_source = $depth_source->related_source($parent);
            $parent = $class->_parentRelationName(schema => $depth_source);
        }
    }
    @joins = (@joins, @indepth);

    my $joins;
    for my $comp (reverse @joins) {
        $joins = { $comp => $joins };
    }

    return { source   => $source,
             join     => $joins,
             on       => $on,
             accessor => $accessor,
             where    => $where };
}


=pod
=begin classdoc

Method used during cloning and import process of object linked to another object (belongs_to relationship)
Clone this object and link the clone to the specified related object
Only clone if object doesn't alredy exist in destination object (based on label_attr_name arg)

@param dest_object_id id of the related object where to import cloned object
@param relationship name of the belongs_to relationship linking to owner object
@optional label_attr_name name of the attr used to know if object already exists in related objects of dest
@optional attrs_clone_handler function called to handle specific attrs cloning, must return the new attrs hash

@return the cloned object

=end classdoc
=cut

sub _importToRelated {
    my ($self, %args) = @_;
    my $class = ref($self) or throw Kanopya::Exception::Method(error => $self);

    General::checkParams(args => \%args, required => [ 'dest_obj_id', 'relationship' ]);

    my $attrs = $self->toJSON(raw => 1); #, no_relations => 1);
    my $caller_class = caller();

    # Don't clone If already exists (based on label_attr_name)
    if (defined $args{label_attr_name}) {
        try {
            return $caller_class->find(hash => {
                       $args{relationship} . '_id' => $args{dest_obj_id},
                       $args{label_attr_name}      => $attrs->{$args{label_attr_name}}
                   });
        }
        catch ($err) {
            # Do not exists, create it.
        }
    }

    # Set the linked entity id to the dest entity id
    $attrs->{$args{relationship} . '_id'} = $args{dest_obj_id};

    # Specific attrs cloning handler callback
    if ($args{attrs_clone_handler}) {
        $attrs = $args{attrs_clone_handler}(attrs => $attrs);
    }

    # Remove all primary keys of hierarchy of the origin obj
    my $srcclass = '';
    for my $subclass (split('::', $class)) {
        $srcclass .= $subclass;
        delete $attrs->{$srcclass->_primaryKeyName};
        $srcclass .= '::';
    }

    # Create the object
    return $caller_class->new(%$attrs);
}


=pod

Utility method used to clone a formula
Clone all objects used in formula and translate formula to use cloned object ids

@param dest_sp_id id of the service provider where to import all cloned objects
@param formula string representing a formula (i.e operators and object ids in the format "idXXX")
@param formula_class class of object used in formula

@return the cloned object

=end classdoc
=cut

sub _cloneFormula {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['dest_sp_id', 'formula', 'formula_class']);

    my $formula = $args{formula};
    # Get ids in formula
    my %ids = map { $_ => undef } ($formula =~ m/id(\d+)/g);
    # Clone objects used in formula
    %ids = map {
        $_ => $args{formula_class}->get(id => $_)->clone(dest_service_provider_id => $args{dest_sp_id})->id
    } keys %ids;

    # Replace ids in formula with cloned objects ids
    $formula =~ s/id(\d+)/id$ids{$1}/g;

    return $formula;
}


=pod
=begin classdoc

Return the delegatee entity on which the permissions must be checked.
By default, permissions are checked on the entity itself.

@return the delegatee entity.

=end classdoc
=cut

sub _delegatee {
    my $self = shift;

    throw Kanopya::Exception::NotImplemented(
              error => "Unable to check permissions on non entity class <$self>, " .
                       "CRUD methods are supported by specifying a delegatee attr."
          );
}


=pod
=begin classdoc

Get the name of the attribute that define the relation to the delegatee object. 
If exists, the permission to create an object of the class is delegated to
the delegatee object on which the user need to have the 'update' permissions.

@return the delegatee attr name.

=end classdoc
=cut

sub _delegateeAttr {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $attrs = $class->_attributesDefinition;
    my @delegatees = grep { defined $attrs->{$_}->{is_delegatee} && $attrs->{$_}->{is_delegatee} == 1 }
                         keys %{ $attrs };

    return (scalar(@delegatees) > 0) ? pop @delegatees : undef;
}


=pod
=begin classdoc

Generic method to get the name of the attribute that identify the object.
Search for an attribute ending by '_name' within all attributes.

@optional attrs the attribute defintion of the object

@return the name of the attribute that identify the object

=end classdoc
=cut

sub _labelAttr {
    my ($self, %args) = @_;
    my $class = ref ($self) || $self;

    try {
        my @names = grep { $_ =~ m/.*_name$/ } keys %{ $class->_attributesDefinition };
        return shift @names;
    }
    catch ($err) {
        return undef;
    }
}


=pod
=begin classdoc

Build the permssions error message from the requested method.

=end classdoc
=cut

sub _permissionDeniedMessage {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'method' ]);

    my $msg  = "Permission denied to " . $self->_methodsDefinition->{$args{method}}->{description};
    my $type = ref($self) ? ($class->_className . " <" . $self->label . ">") : $class->_className;
    $msg =~ s/<object>/$type/g;
    return $msg;
}


=pod
=begin classdoc

Build an array of the base classes that have a schema

@return the array containing all classes in the hierarchy.

=end classdoc
=cut

sub _classHierarchy {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;
    my @supers = Class::ISA::super_path($class);

    my @hierarchy;
    if (defined ($supers[0]) && $supers[0] eq 'BaseDB') {
        @hierarchy = $class->_className;
    }
    else {
        @hierarchy = split(/::/, $class);
    }

    @hierarchy = grep { eval { Kanopya::Database::schema->source($_) }; not $@ } @hierarchy;

    my @klasses;
    return grep { push @klasses, $_; $class->isa(join('::', @klasses))
                                         or (join('::', @klasses) eq join('::', @hierarchy)) } @hierarchy;
}


=pod
=begin classdoc

Return the class type name from a class type id, at the first call,
get all the entries and cache them into a hash for *LOT* faster accesses.

@param id the id of the class type

@return the class type name

=end classdoc
=cut

sub _classType {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, optional => { 'id' => undef, 'classname' => undef });

    if (defined $args{id}) {
        my $classtype = $class->_classTypes->{$args{id}};
        if (! defined $classtype) {
            throw Kanopya::Exception::Internal::NotFound(error => "No class type found with id $args{id}");
        }
        return $classtype;
    }
    elsif (defined ($args{classname})) {
        my @types = grep { $_ =~ "::$args{classname}\$" } values %{ $class->_classTypes };
        if (scalar(@types)) {
            return shift @types;
        }
        throw Kanopya::Exception::Internal::NotFound(error => "No class type found for $args{classname}");
    }
    throw Kanopya::Exception::Internal(error => "You must provide either <id> or <class> as parameter");
}


=pod
=begin classdoc

Return the class type id of the current class.

@param class force using param class instead of current one

@return the class type id or name

=end classdoc
=cut

sub _classTypeId {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'class' => $class });

    my @types = grep { $class->_classTypes->{$_} eq $args{class} } keys %{ $class->_classTypes };
    if (scalar(@types)) {
        return shift @types;
    }
    throw Kanopya::Exception::Internal::NotFound(error => "No class type found for $args{class}");
}


=pod
=begin classdoc

Return the most conrete class name of the class.

@param class force using param class instead of the current one
@return the class name without its hierarchy

=end classdoc
=cut

sub _className {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'class' => $class });

    $args{class} =~ s/.*\:\://g;
    return $args{class};
}


=pod
=begin classdoc

Return the class name at the top of the hierarchy

@return the root class name

=end classdoc
=cut

sub _rootClassName {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'class' => $class });

    $args{class} =~ s/\:\:.*$//g;
    return $args{class};
}


=pod
=begin classdoc

Return the table name of the class

@optinal class use argument as input instead of current class

@return the table name

=end classdoc
=cut

sub _tableName {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'classname' => $class->_className });

    (my $table = $args{classname}) =~ s/([A-Z])/_$1/g;
    return lc(substr($table, 1));
}


=pod
=begin classdoc

Return the table name at the top of the hierarchy

@return the root table name

=end classdoc
=cut

sub _rootTableName {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    return $class->_tableName(classname => $class->_rootClassName);
}


=pod
=begin classdoc

Get the primary key column name

@return the primary key column name.

=end classdoc
=cut

sub _primaryKeyName {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args     => \%args,
                         optional => { 'schema' => undef, 'allow_multiple' => 1 });

    # Do not use optional checkParams mechanism, as the default value is
    # computed even if the value is given.
    $args{schema} = defined $args{schema} ? $args{schema} : $class->_resultSource;

    # If the primary key is multiple, get the first one, but should not occurs
    my @pknames = $args{schema}->primary_columns;
    if (scalar (@pknames) <= 0) {
        throw Kanopya::Exception::Internal(
                  error => "No primary key name found for $class"
              );
    }
    elsif (scalar (@pknames) > 1 && ! $args{allow_multiple}) {
        throw Kanopya::Exception::Internal(
                  error => "Primary key name requested but multiple primary key found for $class"
              );
    }
    return shift @pknames;
}


=pod
=begin classdoc

Find the parent relation name from the primary key name.

@return the parent relation name

=end classdoc
=cut

sub _parentRelationName {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'schema' => undef });

    # Do not use optional checkParams mechanism, as the default value is
    # computed even if the value is given.
    $args{schema} = defined $args{schema} ? $args{schema} : $class->_resultSource;

    # Deduce the parent relaton name from primary key
    try {
        (my $parent = $class->_primaryKeyName(schema => $args{schema}, allow_multiple => 0)) =~ s/_id$//g;
        return $parent;
    }
    catch ($err) {
        return undef;
    }
}


=pod
=begin classdoc

@return the DBIx ResultSource for this class.

=end classdoc
=cut

sub _resultSource {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'classname' => undef, 'ignore_holes' => 1 });

    if (! defined $args{classname}) {
        my $realclass = $class;
        if ($args{ignore_holes}) {
            # Remove classes without table from the hierarchy
            $realclass = join("::", $class->_classHierarchy);
        }
        $args{classname} = BaseDB->_className(class => $realclass);
    }

    try {
        return Kanopya::Database::schema->source($args{classname});
    }
    catch ($err) {
        throw Kanopya::Exception::DB::UnknownSource(error => "$err");
    }
}


=begin classdoc

Set/Get the private insternal dbix object for the instance.

@return the dbix object

=end classdoc
=cut

sub _dbix {
    my ($self, @args) = @_;
    my $class = ref($self)
        or throw Kanopya::Exception::Method(error => "Can't set/get _dbix on class <$self>");

    if (scalar(@args)) {
        $self->{_dbix} = shift @args;
    }
    return $self->{_dbix};
}


=pod
=begin classdoc

Insert row  in database from table name and attributes.

@param attrs hash containing keys / values of the new dbix attributes
@optional table the first table of the hierarchy

@return the object hash with the private _dbix.

=end classdoc
=cut

sub _dbixNew {
    my ($class, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'attrs' ],
                         optional => { 'classname' => $class->_rootClassName });

    my $dbix;
    try {
        $dbix = Kanopya::Database::schema->resultset($args{classname})->new($args{attrs});
        $dbix->insert;
    }
    catch ($err) {
        if ($err =~ m/Duplicate entry/) {
            throw Kanopya::Exception::DB::DuplicateEntry(error => "$err");
        }
        throw Kanopya::Exception::DB(error => "$err");
    }
    return $class->get(id => $class->_dbixPrimaryKey(dbix => $dbix));
}


=pod
=begin classdoc

Instanciate dbix class mapped to corresponding raw in DB.

@param table DB table name
@param hash hash of constraints to find entity

@return the db schema (dbix)

=end classdoc
=cut

sub _dbixSearch {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'class' ], optional => { 'hash' => {} });

    if (defined ($args{rows}) and not defined ($args{page})) {
        $args{page} = 1;
    }

    # Catch specifics warnings to avoid Dancer include warnings to the HTML rendering...
    $SIG{__WARN__} = sub {
        my $warn_msg = $_[0];
        if ($warn_msg =~ m/Prefetching multiple has_many rel/) {
            $log->warn($warn_msg);
        }
        else {
            # TODO Test number of logs if we log in warn level
            $log->debug($warn_msg);
        }
    };

    try {
        return Kanopya::Database::schema->resultset($args{class})->search($args{hash}, {
                   prefetch => $args{prefetch},
                   join     => $args{join},
                   rows     => $args{rows},
                   page     => $args{page},
                   order_by => $args{order_by}
               });
    }
    catch ($err) {
        throw Kanopya::Exception::Internal(error => "$err");
    }
}


=pod
=begin classdoc

Build ans bless an object from the input dbix row.

@param dbix a dbix row representing the object table row

@return the blessed instance

=end classdoc
=cut

sub _dbixBless {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'dbix' ], optional => { 'deep' => 0 });

    my $modulename = BaseDB->_dbixClass(schema => $args{dbix}->result_source);
    General::requireClass($modulename);

    my $self = bless { _dbix => $args{dbix} }, $modulename;

    # TODO: Do not hard code exceptions ("class_type", "component_type", "service_provider_type"),
    #       Those two types have no relation to class_type table,
    #       but have class_type_id as primary key column name.
    if ($args{deep} && $args{dbix}->result_source->from() !~ m/^.*_type$/) {
        return $modulename->get(id => $self->id);
    }
    return $self;
}


=pod
=begin classdoc

Build the name of the class for the specified DBIx row.

@param dbix a dbix row

@return the class name

=end classdoc
=cut

sub _dbixClass {
    my ($class, %args) = @_;
    my $args = @_;

    General::checkParams(args => \%args, required => [ 'schema' ]);

    my $source = $args{schema};
    my $name = $source->source_name;
    try {
        return BaseDB->_classType(classname => $name);
    }
    catch {
        # Our management of class types is really confusing yet...
        while (1) {
            my $parent = $class->_parentRelationName(schema => $source);
            last if ! (defined $parent && $source->has_relationship($parent));
            $source = $source->related_source($parent);
            $name = ucfirst($source->from) . "::" . $name;
        }
        return General::normalizeName($name);
    }
}


=pod
=begin classdoc

Return the primary(ies) key(s) of a row.

@param dbix dbix row of the object

@return the primary key value

=end classdoc
=cut

sub _dbixPrimaryKey {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => [ 'dbix' ], optional => { 'allow_multiple' => 1 });

    # If the primary key is multiple, get the first one, but should not occurs
    my @ids = $args{dbix}->id;
    if (scalar (@ids) <= 0) {
        throw Kanopya::Exception::Internal(
                  error => "No primary key found for $class"
              );
    }
    elsif (scalar (@ids) > 1 && ! $args{allow_multiple}) {
        throw Kanopya::Exception::Internal(
                  error => "Primary key requested but multiple primary key found for $class"
              );
    }
    return shift @ids;
}


=pod
=begin classdoc

Return the dbix at level of the hierarchy specified by class parameter.

@optional classname the level of the hierachy to return the dbix
@optional target the target dbix, allow to request parent or root dbix without specifying a class name
@optional dbix the dbix instance to use instead o the current one 

@return the dbix of the required level

=end classdoc
=cut

sub _dbixParent {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args     => \%args,
                         optional => { 'classname' => '',
                                       'target'    => 'parent',
                                       'dbix'      => ref($self) ? $self->_dbix : undef });

    # Search for the requested class level in the hierarchy
    my $dbix = $args{dbix};
    while (defined $dbix && $class->_className(class => ref($dbix)) ne $args{classname}) {
        my $parent = $class->_parentRelationName(schema => $dbix->result_source);

        # If the root level is requested, stop if the next parent is undefined
        my $schema = $dbix->result_source;
        if (($args{target} eq 'root' && $args{classname} eq '') &&
            (! (defined $parent && $schema->has_relationship($parent)))) {
            last;
        }

        # Go to parent dbix
        $dbix = (defined $parent && $schema->has_relationship($parent)) ? $dbix->$parent : undef;

        # If only one level is requested, stop at the fist loop
        if ($args{target} eq 'parent' && $args{classname} eq '') {
            last;
        }
    }

    if (! defined $dbix && $args{classname} ne '') {
        throw Kanopya::Exception::Internal(
                  error => "The requested dbix class <$args{classname}> not found in the hierarchy"
              );
    }
    return $dbix;
}


=pod
=begin classdoc

@return  the dbix at the top level of the hierarchy.

=end classdoc
=cut

sub _dbixRoot {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'dbix' => ref($self) ? $self->_dbix : undef });

    return $self->_dbixParent(dbix => $args{dbix}, target => 'root');
}


=pod
=begin classdoc

If empty, fill the class types cache with values from db.

@return the class types cache

=end classdoc
=cut

sub _classTypes {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    # If the class type cache not loaded, fill with class types from db
    if (! defined $class_type_cache) {
        my $class_types = $class->_dbixSearch(class => "ClassType");
        while (my $class_type = $class_types->next) {
            $class_type_cache->{$class_type->get_column("class_type_id")}
                = $class_type->get_column("class_type");
        }
    }
    return $class_type_cache;
}


=pod
=begin classdoc

Update the PERL5LIB by adding additional components paths.

=end classdoc
=cut

sub _loadcomponents {
    my ($self, @args) = @_;

    for my $component (glob(Kanopya::Config::getKanopyaDir . "/lib/component/*")) {
        push @INC, $component;
    }
}


=pod
=begin classdoc

We define an AUTOLOAD to mimic the DBIx behaviour, it simply calls 'getAttr'
that returns the specified attribute or the relation blessed to a BaseDB object.

@return the value returned by the call of the requested attribute.

=end classdoc
=cut

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $class = ref($self) || $self;

    my @autoload = split(/::/, $AUTOLOAD);
    my $accessor = $autoload[-1];

    if (ref($self)) {
        if (scalar (@args)) {
            return $self->setAttr(name => $accessor, value => $args[0], save => 1);
        }
        else {
            return $self->getAttr(name => $accessor, deep => 1);
        }
    }
    throw Kanopya::Exception::UnkonwnMethod(error => "$class->$accessor");
}


=pod
=begin classdoc

Method called at the object deletion.

=end classdoc
=cut

sub DESTROY {}


# Update the PERL5LIB for components
BEGIN {
    _loadcomponents();
}

1;
