# base class to manage inheritance throw relational database

package BaseDB;

use strict;
use warnings;
use Data::Dumper;
use Administrator;
use General;
use POSIX qw(ceil);
use Hash::Merge;
use Class::ISA;
use vars qw($AUTOLOAD);
use Log::Log4perl "get_logger";

my $log = get_logger("basedb");
my $errmsg;
my %class_type_cache;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        toString => {
            description => 'toString',
            perm_holder => 'entity',
        },
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
        methodCall => {
            description => 'Call an object method',
        },
    };
}


=head2

    Return all the available methods for this object

=cut

sub getMethods {
  my $self      = shift;
  my $class     = ref($self) || $self;
  my $methods   = {};
  my @supers    = Class::ISA::self_and_super_path($class);
  my $merge     = Hash::Merge->new();
  for my $sup (@supers) {
    if ($sup->can('methods')) {
      $methods    = $merge->merge( $methods, $sup->methods() );
    }
  }
  return $methods;
}

=head2

    Based on a class name, requireClass imports the right Perl module
    of the corresponding class

=cut

sub requireClass {
    my $location = shift;
    $location =~ s/\:\:/\//g;
    $location .= '.pm';
    eval { require $location; };
    if ($@) {
        throw Kanopya::Exception::Internal::UnknownClass(
            error => "Could not find $location :\n$@"
        );
    }
}

=head2

    Return a hash ref containing all ATTR_DEF for each class
    in the hierarchy

=cut

sub getAttrDefs {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, optional => { 'group_by' => 'none' });

    my $attributedefs = {};
    my @classes = split(/::/, (split("=", "$class"))[0]);

    while(@classes) {
        my $attr_def = {};
        my $currentclass = join('::', @classes);

        if ($currentclass ne "BaseDB") {
            requireClass($currentclass);
            eval {
                $attr_def = $currentclass->getAttrDef();
            };

            my $schema;
            eval {
                $schema = $class->{_dbix}->result_source();
            };
            if ($@) {
                my $adm = Administrator->new();
                $schema = $adm->{db}->source(_buildClassNameFromString($currentclass));
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
            $attributedefs->{$currentclass} = $attr_def;
        }
        pop @classes;
    }

    if ($args{group_by} eq 'module') {
        return $attributedefs;
    }

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');

    # Finally merge all module attrs into one level hash
    my $result = {};
    foreach my $module (keys %$attributedefs) {
        $result = $merge->merge($result, $attributedefs->{$module});
    }
    return $result;
}

=head2

    Check attribute validity in the class hierarchy
    Return dbix class row where the attr is found

=cut

sub checkAttr {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;

    General::checkParams(args => \%args, required => ['name']);

    if(! exists $args{value}) {
        $errmsg = ref($self) . " checkAttr need a value named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my $attributes_def = $class->getAttrDefs();
    if (exists $attributes_def->{$args{name}} && defined $args{value} &&
        $args{value} !~ m/($attributes_def->{$args{name}}->{pattern})/) {

        $errmsg = "$class"."->checkAttr detect a wrong value $args{value} for param: $args{name} on class $class";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}

=head2

    Check attributes validity in the class hierarchy
    and build as the same time a hasref structure to pass to 'new' method
    of dbix resultset for the root class of the hierarchy

=cut

sub checkAttrs {
    my ($self, %args) = @_;
    my $class = ref($self) || $self;
    my $final_attrs = {};
    my $attributes_def = $class->getAttrDefs(group_by => 'module');
    
    General::checkParams(args => \%args, required => ['attrs']);

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

                if (((not defined $value) and $attributes_def->{$module}->{$attr}->{is_mandatory}) or
                    ((defined $value) and $value !~ m/($attributes_def->{$module}->{$attr}->{pattern})/)) {
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

=head2

    Create a new instance of the class.
    It inserts a entry for every class of the hierarchy,
    every entry having a foreign key to its parent entry

=cut

sub new {
    my ($class, %args) = @_;
    my $hash = \%args;

    # Extract relation for futher handling
    my $relations = extractRelations(hash => $hash);

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
    return $self;
}

=head2

    Update an instance by setting values for attribute taht differs,
    also handle the update of relations.

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
        if ("$hash->{$attr}" ne "$currentvalue") {
            $self->setAttr(name => $attr, value => $hash->{$attr});

            if (not $updated) { $updated = 1; }
        }
    }
    if ($updated) { $self->save(); }

    # Populate relations
    $self->populateRelations(relations => $relations);
    return $self;
}

=head2

    Extend an object instance to a concreter type.

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

=head2

    Generalize an object instance to a parent type.

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

sub newDBix {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'attrs' ]);

    my $adm = Administrator->new();
    my $subclass = defined $args{subclass} ? $args{subclass} : $class;
    my $dbixroot = $adm->_newDbix(table => _rootTable($subclass), row => $args{attrs});

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

=head2

    Construct the proper BaseDB based instance from
    a DBIx row

=cut

sub fromDBIx {
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'row' ]);

    my $name = classFromDbix($args{row}->result_source);

    requireClass($name);

    # We need to use prefetch to get the parent/childs attrs,
    # and use the concrete class type. Use 'get' for instance.

#    return bless {
#        _dbix      => $args{row},
#    }, $name;

    return $name->get(id => getRowPrimaryKey(row => $args{row}));
}

=head2

    Retrieve a value given a name attribute ; search this
    atribute throw the whole class hierarchy

=cut

sub getAttr {
    my $self = shift;
    my $class = ref($self);
    my %args = @_;

    my $dbix = $self->{_dbix};
    my $attr = $class->getAttrDef()->{$args{name}};
    my $value = undef;
    my $found = 1;

    General::checkParams(args => \%args, required => ['name']);

    # Recursively search in the dbix objets, following
    # the 'parent' relation
    while ($found) {
        if ($dbix->has_column($args{name})) {
            $value = $dbix->get_column($args{name});
            last;
        }
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
        elsif ($self->can($args{name}) and defined $attr and $attr->{is_virtual}) {
            my $method = $args{name};
            $value = $self->$method();
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

=head2

    Retrieve all keys/values in the class hierarchy

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

=head2

    Set one name attribute with the given value ;
    search this attribute throw the whole class hierarchy,
    and check attribute validity

=cut

sub setAttr {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['name']);

    if(! exists $args{value}) {
        $errmsg = ref($self) . " setAttr need a value named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my ($name, $value) = ($args{name}, $args{value});
    my $dbix = $self->{_dbix};
    $self->checkAttr(%args);
    
    my $found = 0;
    while(1) {
        # Search for attr in this dbix
        if ( $dbix->has_column($name) ) {
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

    if(not $found) {
        $errmsg = ref($self) . " setAttr no attr name $args{name}!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    } 
    return $value;
}

=head2

    Retrieve one instance from an id

=cut

sub get {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => ['id']);

    my $adm = Administrator->new();
    eval {
        my $dbix = $adm->getRow(id => $args{id}, table => _rootTable($class));
        $class   = $dbix->class_type->get_column('class_type');
    };
    if ($@) {
        $log->debug("Unable to retreive concrete class name, using $class.");
    }

    my $table = _buildClassNameFromString($class);
    my $location = General::getLocFromClass(entityclass => $class);
    eval { require $location; };
    if ($@) {
        throw Kanopya::Exception::Internal::UnknownClass(
                  error => "Could not find $location :\n$@"
              );
    }

    my $dbix = $adm->getRow(id => $args{id}, table => $table);
    my $self = {
        _dbix => $dbix,
    };

    bless $self, $class;
    return $self;
}

=head2

    Return the class type name from a class type id
    At the first call, get all the entries and cache them
    into a hash for *LOT* faster accesses

=cut

sub getClassType {
    my %args = @_;
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

=head2

    Return the join query required to get all the attributes
    of the whole class hierarchy

=cut

sub getJoin {
    my ($class) = @_;

    my $parent_join;
    my @hierarchy = split(/::/, $class);
    my $depth = scalar @hierarchy;
    my $n = $depth;
    my $adm = Administrator->new();
    while ($n > 0) {
        last if $hierarchy[$n - 1] eq "BaseDB";
        $parent_join = $adm->{db}->source($hierarchy[$n - 1])->has_relationship("parent") ?
                           ($parent_join ? { parent => $parent_join } : { "parent" => undef }) :
                           $parent_join;
        $n -= 1;
    }

    return $parent_join;
}

=head2

    Return the JOIN query to get the attributes of a multi level
    depth relationship

=cut

sub getJoinQuery {
    my ($class, @comps) = @_;

    my $adm = Administrator->new();
    my $source = $adm->{db}->source(_buildClassNameFromString($class));

    my @joins;
    for my $comp (@comps) {
        my @segment = ();
        while (! $source->has_relationship($comp)) {
            @segment = ("parent", @segment);
            last if ! $source->has_relationship("parent");
            $source = $source->related_source("parent");
        }

        $source = $source->related_source($comp);
        @joins = (@joins, @segment, $comp);
    }

    my $joins;
    for my $comp (reverse @joins) {
        $joins = { $comp => $joins };
    }

    return $joins;
}

=head2

    Return the entries that match the 'hash' filter
    It also accepts more or less the same parameters than
    DBIx 'search' method.

    It fetches the attributes of the whole class hierarchy
    and returns an object as a BaseDB derived object

=cut

sub search {
    my ($class, %args) = @_;
    my @objs = ();

    General::checkParams(args => \%args, required => ['hash']);

    my $table = _buildClassNameFromString($class);
    my $adm = Administrator->new();
    my $join = $class->getJoin() || {};

    for my $filter (keys %{$args{hash}}) {
        my @comps = split('\.', $filter);
        my $value = $args{hash}->{$filter};

        if (scalar (@comps) > 1) {
            my $value = $args{hash}->{$filter};
            my $attr = pop @comps;

            delete $args{hash}->{$filter};

            my $merge = Hash::Merge->new('RETAINMENT_PRECEDENT');
            $join = $merge->merge($join, $class->getJoinQuery(@comps));
            
            $args{hash}->{$comps[-1] . '.' . $attr} = $value;
        }
    }

    my $rs = $adm->_getDbixFromHash('table'    => $table,
                                    'hash'     => $args{hash},
                                    'page'     => $args{page},
                                    'join'     => $join,
                                    'rows'     => $args{rows},
                                    'order_by' => $args{order_by});

    while ( my $row = $rs->next ) {
        my $obj = {
             _dbix => $row,
        };

        my $parent = $row;
        while ($parent->can('parent')) {
            $parent = $parent->parent;
        }

        my $class_type;
        if ($parent->has_column("class_type_id") and $class ne "ClassType") {
            $class_type = getClassType(id => $parent->get_column("class_type_id"));

            if (length($class_type) > length($class)) {
                $obj = Entity->get(id => $parent->get_column("entity_id"));
            }
        }
        else {
            $class_type = $class;
        }

        bless $obj, $class_type;

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

    my $total = (defined ($args{page}) or defined ($args{rows})) ?
                    $rs->pager->total_entries : $rs->count;

    if (defined ($args{dataType}) and $args{dataType} eq "hash") {
        return {
            page    => $args{page} || 1,
            pages   => ceil($total / ($args{rows} || ($args{page} ? 10 : 1))),
            records => scalar @objs,
            rows    => \@objs,
            total   => $total,
        }
    }

    return @objs;
}

=head2

    Return a single element matching the specified criterias
    Take the same arguments as 'search'

=cut

sub find {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => ['hash']);

    my @objects = $class->search(%args);

    my $object = pop @objects;
    if (! defined $object) {
        throw Kanopya::Exception::Internal::NotFound(
                  error => "No entry found for " . $class . ", with hash " . Dumper($args{hash})
              );
    }
    return $object;
}

=head2

    Store the object in the database.
    Create it if it doesn't exist, update it otherwise.

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

=head2

    Remove records from the entire class hierarchy

=cut

sub delete {
    my ($self, %args) = @_;
    my $dbix = $self->{_dbix};

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

=head2

    Return the string representation of the object

=cut

sub toString {
    my $self = shift;
    return ref($self);
}

=head2

    Return the object as a hash so that it can be safely be
    converted to JSON. Should be named differently but hey...

=cut

sub toJSON {
    my ($self, %args) = @_;
    my $class = ref ($self) || $self;

    General::checkParams(args     => \%args,
                         optional => { 'no_relations' => 0, 'model' => undef });

    my $pk;
    my $hash = {};
    my $attributes;
    my $conreteclass = $class;
    my $merge = Hash::Merge->new();

    $attributes = $class->getAttrDefs(group_by => 'module');
    foreach my $class (keys %$attributes) {
        foreach my $attr (keys %{$attributes->{$class}}) {
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
        my $n = $depth;
        my $parent;

        for (my $n = $depth - 1; $n >= 0; $n--) {
            $parent = $adm->{db}->source($hierarchy[$n]);
            my @relnames = $parent->relationships();
            for my $relname (@relnames) {
                my $relinfo = $parent->relationship_info($relname);

                if (scalar (grep { $_ eq (split('::', $relinfo->{source}))[-1] } @hierarchy) == 0 and
                    $relinfo->{attrs}->{is_foreign_key_constraint} or
                    $relinfo->{attrs}->{accessor} eq "multi") {

                    my $resource = lc((split("::", $relinfo->{class}))[-1]);
                    $resource =~ s/_//g;

                    $hash->{relations}->{$relname} = $relinfo;
                    $hash->{relations}->{$relname}->{from} = $hierarchy[$n];
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
        $hash->{pk} = $self->getId;

        my $label = $self->getLabelAttr(attrs => $hash);
        $hash->{label} = $label ? $self->getAttr(name => $label) : $self->getId;
    }

    return $hash;
}

=head2

    Remove relations values from values, and return its.

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

=head2

    Create or update relations.

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

=head2

    Return the primary(ies) key(s) of a row.

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

=head2

    Get the name of the attribute that identify the object.

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

=head2

    Generic creation method.

=cut

sub create {
    my $class = shift;
    my %args = @_;

    $class->new(%args);
}

=head2

    Generic deletion method.

=cut

sub remove {
    my $self = shift;
    my %args = @_;

    $self->delete();
}


=head2

    Get the primary key column name

=cut

sub getPrimaryKey {
    my $self = shift;

    return ($self->{_dbix}->result_source->primary_columns)[0];
}

=head2

    Get the primary key of the object

=cut

sub getId {
    my $self = shift;

    return $self->id;
}

=head2

    Get the primary key of the object

=cut

sub id {
    my $self = shift;

    return $self->{_dbix}->get_column($self->getPrimaryKey);
}

=head2

    Return the parent class name

=cut

sub _parentClass {
    my ($class) = @_;
    $class =~ s/\:\:[a-zA-Z0-9]+$//g;
    return $class;
}

=head2

    Remove the top of hierarchy class

=cut

sub _childClass {
    my ($class) = @_;
    $class =~ s/^[a-zA-Z0-9]+\:\://g;
    return $class;
}

=head2

    Return the class name without its hierarchy

=cut

sub _buildClassNameFromString {
    my ($class) = @_;
    $class =~ s/.*\:\://g;
    return $class;
}

sub getForeignKeyFromCond {
    my (%args) = @_;
    
    General::checkParams(args => \%args, required => [ 'cond' ]);
    
    $args{cond} =~ s/.*foreign\.//g;
    return $args{cond};
}

sub getKeyFromCond {
    my (%args) = @_;

    General::checkParams(args => \%args, required => [ 'cond' ]);

    $args{cond} =~ s/.*self\.//g;
    return $args{cond};
}

=head2

    Get the class name at the top of the hierarchy
    of a full class name

=cut

sub _rootTable {
    my ($class) = @_;
    $class =~ s/\:\:.*$//g;
    return $class;
}

=head2

    Convert a class name to table name

=cut

sub _classToTable {
    my ($class) = @_;

    $class =~ s/([A-Z])/_$1/g;
    my $table = lc( substr($class, 1) );

    return $table;
}

=head2

    Normalize the specified name by removing underscores
    and upper casing the characters that follows

=cut

sub normalizeName {
    my $name = shift;
    my $i = 0;
    while ($i < length($name)) {
        if (substr($name, $i, 1) eq "_") {
            $name = substr($name, 0, $i) . ucfirst(substr($name, $i + 1, 1)) . substr($name, $i + 2)
        }
        $i += 1;
    }

    return ucfirst($name);
};

=head2

    Returns the name of the Kanopya class for the
    specified DBIx table schema

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

=head2

    Method used by the api as entry point for methods calls.
    It is convenient for centralizing permmissions checking.

=cut

sub methodCall {
    my $self = shift;
    my $class = ref $self;
    my %args = @_;

    my $adm = Administrator->new();

    General::checkParams(args => \%args, required => [ 'method' ], optional => { 'params' => {} });

    # Call the requested method
    my $method = $args{method};
    return $self->$method(%{$args{params}});
}

=head2

    We define an AUTOLOAD to mimic the DBIx behaviour.
    It simply calls 'getAttr' that returns the specified
    attribute or the relation blessed to a BaseDB object

=cut

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $accessor = $autoload[-1];

    return $self->getAttr(name => $accessor);
}

# DESTROY definition required by AUTOLOAD
sub DESTROY { }

1;
