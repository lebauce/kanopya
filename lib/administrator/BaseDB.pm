# base class to manage inheritance throw relational database

package BaseDB;

use Data::Dumper;
use Administrator;
use General;
use POSIX qw(ceil);
use Hash::Merge;
use Class::ISA;


use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("administrator");
my $errmsg;
my %class_type_cache;

sub methods {
    return { };
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
    my $class = shift;
    my $result = {};
    my @classes = split(/::/, (split("=", "$class"))[0]);

    while(@classes) {
        my $attr_def = {};
        my $currentclass = join('::', @classes);
        if ($currentclass ne "BaseDB") {
            requireClass($currentclass);

            eval {
                $attr_def = $currentclass->getAttrDef();
            };
        }

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
            if (($relname ne "parent") &&
                ($relinfo->{attrs}->{is_foreign_key_constraint}) &&
                ($schema->has_column($relname . "_id"))) {
                $attr_def->{$relname . "_id"} = {
                    pattern      => '^\d*$',
                    is_mandatory => 0,
                    is_extended  => 0
                };
            }
        }

        for my $column ($schema->columns) {
            if (not defined ($attr_def->{$column})) {
                $attr_def->{$column} = {
                    pattern      => '^.*$',
                    is_mandatory => 0,
                    is_extended  => 0
                };
            }
        }

        if ($attr_def) {
            $result->{$currentclass} = $attr_def;
        }

        pop @classes;
    }

    return $result;
}

=head2

    Get the primary key of the object

=cut

sub getId {
    my $self = shift;

    return $self->{_dbix}->get_column(($self->{_dbix}->result_source->primary_columns)[0]);
}

=head2

    Return the class name without its hierarchy

=cut

sub _buildClassNameFromString {
    my ($class) = @_;
    $class =~ s/.*\:\://g;
    return $class;
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

    Check attribute validity in the class hierarchy
    Return dbix class row where the attr is found

=cut

sub checkAttr {
    my $self = shift;
    my $class = ref($self) || $self;
    my %args = @_;

    General::checkParams(args => \%args, required => ['name']);
    if(! exists $args{value}) {
        $errmsg = ref($self) . " checkAttr need a value named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    
    my $attributes_def = $class->getAttrDefs();
    foreach my $module (keys %$attributes_def) {
        if (exists $attributes_def->{$module}->{$args{name}} && defined $args{value}){
            if($args{value} !~ m/($attributes_def->{$module}->{$args{name}}->{pattern})/){
                $errmsg = "$class"."->checkAttr detect a wrong value $args{value} for param : $args{name} on class $module";
                $log->error($errmsg);
                throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
            }
            next;
        }
    }
}

=head2

    Check attributes validity in the class hierarchy
    and build as the same time a hasref structure to pass to 'new' method
    of dbix resultset for the root class of the hierarchy

=cut

sub checkAttrs {
    my $self = shift;
    my $class = ref($self) || $self;
    my %args = @_;
    my $final_attrs = {};
    my $attributes_def = $class->getAttrDefs();
    
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
                if(not defined $value or $value !~ m/($attributes_def->{$module}->{$attr}->{pattern})/) {
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
        my $classname = _buildClassNameFromString($modules[$i+1]);
        $classname =~ s/([A-Z])/_$1/g;
        my $relation = lc( substr($classname, 1) );
        $final_attrs->{$modules[$i]}->{$relation} = $final_attrs->{$modules[$i+1]};
    }
    
    return $final_attrs->{$modules[0]};
}

=head2

    Create a new instance of the class.
    It inserts a entry for every class of the hierarchy,
    every entry having a foreign key to its parent entry

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $attrs = $class->checkAttrs(attrs => \%args);

    my $adm = Administrator->new();

    # Get the class_type_id for class name
    eval {
        my $rs = $adm->_getDbixFromHash(table => "ClassType",
                                     hash  => { class_type => $class })->single;

        $attrs->{class_type_id} = $rs->get_column('class_type_id');
    };
    if ($@) {
        $errmsg = "Unregistred or abstract class name <$class>, assuming it is not an Entity.";
        $log->debug($errmsg);
    }

    my $dbixroot = $adm->_newDbix(table => _rootTable($class), row => $attrs);
    $dbixroot->insert;
    my $id = $dbixroot->id;

    my $self = {
        _dbix => $adm->getRow(table => _buildClassNameFromString($class),
                              id    => $id),
        _entity_id => $id
    };

    bless $self, $class;
    return $self;
}

=head2

    Construct the proper BaseDB based instance from
    a DBIx row

=cut

sub fromDBIx {
    my %args = @_;

    my $name = classFromDbix($args{row}->result_source);
    return bless {
        _dbix      => $args{row},
        _entity_id => $args{row}->id
    }, $name;
}

=head2

    Retrieve a value given a name attribute ; search this
    atribute throw the whole class hierarchy

=cut

sub getAttr {
    my $self = shift;
    my %args = @_;
    my $dbix = $self->{_dbix};
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
                $value = fromDBIx(row => $dbix->$name);
            }
            last;
        }
        elsif ($dbix->can('parent')) {
            $dbix = $dbix->parent;
            next;
        } else {
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
    my $self = shift;
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
    my $self = shift;
    my %args = @_;

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
    my $class = shift;
    my %args = @_;

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
    my $class = shift;

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
    my $class = shift;
    my @comps = @_;

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
    my $class = shift;
    my %args = @_;
    my @objs = ();

    General::checkParams(args => \%args, required => ['hash']);

    my $table = _buildClassNameFromString($class);
    my $adm = Administrator->new();
    my $join = $class->getJoin();

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
        if ($parent->has_column("class_type_id")) {
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
    my $class = shift;
    my %args = @_;
    my @objs = ();

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
    my $self = shift;
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
    my $self = shift;
    my $dbix = $self->{_dbix};
    # Search for first mother table in the hierarchy
    while(1) {
        if($dbix->can('parent')) {
            # go to parent dbix
            $dbix = $dbix->parent;
            next;
        } else {
            last;
        }
    }
    $dbix->delete;
}

=head2

    Return the string representation of the object

=cut

sub toString{
    return "";
}

=head2

    Return the object as a hash so that it can be safely be
    converted to JSON. Should be named differently but hey...

=cut

sub toJSON {
    my ($self, %args) = @_;
    my $pk;
    my $hash = {};
    my $class = ref ($self) || $self;
    my $attributes;
    my $merge = Hash::Merge->new();

    eval {
        $attributes = $class->getAttrDefs();
    };
    if ($@) {
        $attributes = $self->getAttrDefs();
    }

    foreach my $class (keys %$attributes) {
        foreach my $attr (keys %{$attributes->{$class}}) {
            if (defined $args{model}) {
                $hash->{attributes}->{$attr} = $attributes->{$class}->{$attr};
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
                if ((scalar (grep { $_ eq (split('::', $relinfo->{source}))[-1] } @hierarchy) == 0) and
                    ($relinfo->{attrs}->{is_foreign_key_constraint}) or
                    ($relinfo->{attrs}->{accessor} eq "multi")) {
                    my $resource = lc((split("::", $relinfo->{class}))[-1]);
                    $resource =~ s/_//g;
                    $hash->{relations}->{$relname} = $relinfo;
                    $hash->{relations}->{$relname}->{from} = $hierarchy[$n];
                    $hash->{relations}->{$relname}->{resource} = $resource;
                    delete $hash->{attributes}->{$relname . "_id"};
                }
            }

            my $klass = join("::", @hierarchy);
            pop @hierarchy;
        }

        $hash->{methods}    = $self->getMethods;

        $hash->{pk} = {
            pattern      => '^\d*$',
            is_mandatory => 1,
            is_extended  => 0
        };

    }
    else {
        $hash->{pk} = $self->getId;
    }

    return $hash;
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

sub DESTROY {
}

1;
