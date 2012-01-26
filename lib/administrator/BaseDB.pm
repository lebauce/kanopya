# base class to manage inheritance throw relational database

package BaseDB;

use Data::Dumper;
use Administrator;
use General;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");
my $errmsg;

# getAttrDefs : return a hash ref containing all ATTR_DEF for each class
# in the hierarchy

sub getAttrDefs {
	my $class = shift;
	my $result = {};
	my @classes = split(/::/, $class);
	while(@classes) {
		my $currentclass = join('::', @classes);
		my $location = $currentclass;
		$location =~ s/\:\:/\//g;
		$location .= '.pm';
		eval { require $location; };
		my $attr_def = eval { $currentclass->getAttrDef() };
		if($attr_def) {
			$result->{$currentclass} = $attr_def;
		}
		pop @classes;
	}
	return $result;
}

sub _buildClassName {
    my ($class) = @_;
    $class =~ s/.*\:\://g;
    return $class;
}

sub _rootTable {
	my ($class) = @_;
	$class =~ s/\:\:.*$//g;
	return $class;
}

# checkAttrs : check attribute validity in the class hierarchy 
# return dbix class row where the attr is found

sub checkAttr {
	my $self = shift;
    my $class = ref($self) || $self;
    my %args = @_;

    General::checkParams(args => \%args, required => ['name', 'value']);
    
    my $attributes_def = $class->getAttrDefs();
    foreach my $module (keys %$attributes_def) {
		if (exists $attributes_def->{$module}->{$args{name}}){
			if($args{value} !~ m/($attributes_def->{$module}->{$args{name}}->{pattern})/){
				$errmsg = "$class"."->checkAttr detect a wrong value $args{$value} for param : $args{name} on class $module";
				$log->error($errmsg);
				throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
			}
			next;
		} 
	}
}


# checkAttrs : check attributes validity in the class hierarchy 
# and build as the same time a hasref structure to pass to 'new' method
# of dbix resultset for the root class of the hierarchy

sub checkAttrs {
    my $self = shift;
    my $class = ref($self) || $self;
    my %args = @_;
    my $final_attrs = {};
    my $attributes_def = $class->getAttrDefs();
    
    $log->debug('>>>>>>> '.Dumper $attributes_def);
	
    General::checkParams(args => \%args, required => ['attrs']);  

	foreach my $module (keys %$attributes_def) {
		#$log->debug("$module added to sorted_attrs");
		$final_attrs->{$module} = {};
	}

	my $attrs = $args{attrs};
    # search unknown attribute or invalid value attribute
    ATTRLOOP:
    foreach my $attr (keys(%$attrs)) { 
        foreach my $module (keys %$attributes_def) {
			if (exists $attributes_def->{$module}->{$attr}){
				my $value = $attrs->{$attr};
				if($value !~ m/($attributes_def->{$module}->{$attr}->{pattern})/) {
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
		my $classname = _buildClassName($modules[$i+1]);
		my $relation = lc($classname);
		$final_attrs->{$modules[$i]}->{$relation} = $final_attrs->{$modules[$i+1]};
	}
    
    return $final_attrs->{$modules[0]};
}

# new : return dbix resultset with full class hierarchy of this 

sub new {
    my $class = shift;
    my %args = @_;
    
    my $attrs = $class->checkAttrs(attrs => \%args);
    $log->debug('checkAttrs for root class insertion return '.Dumper($attrs));
       
    my $adm = Administrator->new();
    my $dbixroot = $adm->_newDbix(table => _rootTable($class), row => $attrs);
    $dbixroot->insert;
    my $id = $dbixroot->id;
    if($id) {
		$log->debug("$class successully inserted in database");
	}
    
    my $self = {
        _dbix => $adm->getRow(table => _buildClassName($class), id => $id),
        _entity_id => $id
    };
    $log->debug('dbix object type retrieve : '.ref($self->{_dbix}));
    bless $self, $class;
    return $self;
}

# getAttr : retrieve a value given a name attribute ; search this
# atribute throw the whole class hierarchy

sub getAttr {
    my $self = shift;
    my %args = @_;
    my $dbix = $self->{_dbix};
    my $value = undef;
    my $found = 0;
    
    General::checkParams(args => \%args, required => ['name']);

	while(1) {	
		# Search for attr in this dbix
		if ( $dbix->has_column($args{name}) ) {
			$value = $dbix->get_column($args{name});
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
		$errmsg = ref($self) . " getAttr no attr name $args{name}!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal(error => $errmsg);
    } 
    return $value;
}

# getAttrs : retrieve all keys/values in the class hierarchy

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


# setAttr : set one name attribute with the given value ;
# search this attribute throw the whole class hierarchy, 
# and check attribute validity

sub setAttr {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['name', 'value']);
	
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

# get : retrieve one instance from an id

sub get {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);

    my $table = _buildClassName($class);
    my $adm = Administrator->new();
    my $dbix = $adm->getRow(id=>$args{id}, table => $table);
    my $self = {
        _dbix => $dbix,
    };

    bless $self, $class;
    return $self;
}

# search : retrieve several instance via a hash ref filter 

sub search {
    my $class = shift;
    my %args = @_;
    my @objs = ();

    General::checkParams(args => \%args, required => ['hash']);

    my $table = _buildClassName($class);
    my $adm = Administrator->new();
    
    my $rs = $adm->_getDbixFromHash( table => $table, hash => $args{hash} );

    while ( my $row = $rs->next ) {
        my $obj = eval { $class->get(id => $row->id); };
        $log->debug($obj->toString);
        if($@) {
            my $exception = $@; 
            if(Kanopya::Exception::Permission::Denied->caught()) {
                $log->info("no right to access to object <$table> with <$row->id>");
                next;
            } 
            else { $exception->rethrow(); } 
        }
        else { push @objs, $obj; }
    }
    
    return  @objs;
}

# save : store records in database ;
# create them in not exists, update them otherwise

sub save {
	my $self = shift;
    my $dbix = $self->{_dbix};

    my $id;
    if ( $dbix->in_storage ) {
        $log->debug('in storage !');
        # MODIFY existing db obj
        $dbix->update;
        while(1) {	
			if($dbix->can('parent')) {
				$dbix = $dbix->parent;
				$dbix->update;				
				next;
			} else {
				last;
			}
		}
    } else {
		$errmsg = "$class" . "->save can't be called on a non saved instance! (new has not be called)";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
        
    }
    $log->info(ref($self)." updated in database");
    return $id;
}

# delete : remove records from the entire class hierarchy

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

1;
