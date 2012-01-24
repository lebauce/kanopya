# base class to manage inheritance throw relational database

package BaseDB;

use Administrator;

# _buildAttrsHierarchy : given a flat attributes hash ref, build 
# attrs hash ref with correct class hierarchy to call 
# result('concrettable')->new($hash)

sub _buildAttrsHierarchy {

}

sub getAttrDefs{

}

sub _buildClassName {
    my ($class) = @_;
    $class =~ s/.*\:\://g;

    return $class;
}

# à voir si on garde

sub getExtendedAttrs  {}

# checkAttrs : check attribute(s) validity in the class hierarchy 
# return attrs hash ref with correct class hierarchy to class 
# result('concrettable')->new($hash)

sub checkAttrs {
    my $class = shift;
    my %args = @_;
    my (%global_attrs, %ext_attrs);
    my $attr_def = $class->getAttrDefs();

    General::checkParams(args => \%args, required => ['attrs']);  

    my $attrs = $args{attrs};
    foreach my $attr (keys(%$attrs)) {
        if (exists $attr_def->{$attr}){
            $log->debug("Field <$attr> and value in attrs <$attrs->{$attr}>");
            if($attrs->{$attr} !~ m/($attr_def->{$attr}->{pattern})/){
                $errmsg =  "$class" . "->checkAttrs detect a wrong value ($attrs->{$attr}) for param : $attr";
                $log->error($errmsg);
                $log->debug("Can't match $attr_def->{$attr}->{pattern} with $attrs->{$attr}");
                throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
            }
            if ($attr_def->{$attr}->{is_extended}){
                $ext_attrs{$attr} = $attrs->{$attr};
            }
            else {
                $global_attrs{$attr} = $attrs->{$attr};
            }
        }
        else {
            $errmsg = "$class" . "->checkAttrs detect a wrong attr $attr !";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
        }
    }
    foreach my $attr (keys(%$attr_def)) {
        if (($attr_def->{$attr}->{is_mandatory}) && (! exists $attrs->{$attr})) {
            $errmsg = "$class" . "->checkAttrs detect a missing attribute $attr !";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
        }
    }
    #TODO Check if id (systemimage, kernel, ...) exist and are correct.
    return {global => \%global_attrs, extended => \%ext_attrs};
}

# new : return dbix resultset with full class hierarchy of this 

sub new {
    my $class = shitf;
    my %args = @_;
    
    my $attrs = checkAttrs(class => $class, attrs => \%args);
    my $adm = Administrator->new();
    my $self = {
        _dbix => $adm->_newDBIx(table => _buildClassName($class), row => $attrs),
    };
    bless $self, $class;
    return $self;
}

# getAttr : retrieve a value given a name attribute ; search this
# atribute throw the whole class hierarchy

sub getAttr {
    my $self = shift;
    my %args = @_;
    my $data = $self->{_dbix};
    my $value = undef;
    
    General::checkParams(args => \%args, required => ['name']);

    # Search for attr in base class
    if ( $data->has_column($args{name}) ) {
        $value = $data->get_column($args{name});
        if (defined $value) {
            $log->debug(ref($self) . " getAttr of $args{name} : <$value>");
        }
        else {
            $log->debug(ref($self) . " getAttr of $args{name}  return undef");
        }
    }
    # Search for attr in extended attrs of base class
    elsif ( exists $self->{_ext_attrs}{ $args{name} } ) {
        $value = $self->{_ext_attrs}{ $args{name} };
        $log->debug(ref($self) . " getAttr (extended) of $args{name} : $value");

	}
    # Search for attr in parrent, otherwise throw attr rror
    else {
        eval { $value = $self->SUPER::getAttr($args{name}); };
        if($@) {
            $errmsg = ref($self) . " getAttr no attr name $args{name}!";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
    }
    return $value;
}

# setAttr : set one (or several) name attribute with the given value ;
# search this (these) attribute throw the whole class hierarchy, 
# and check attribute validity

sub setAttr {
    my $self = shift;
    my %args = @_;
    my $data = $self->{_dbix};

    General::checkParams(args => \%args, required => ['attrs']);

    my $attrs = $args{attrs};
    while ( (my $name, my $value) = each %$attrs ) {
        $self->checkAttr(name => $name, value => $value);

        if( $data->has_column($name) ) {
            $data->set_column($name, $value);
        }
        elsif( $self->extension() ) {
            $self->{ _ext_attrs }{ $name } = $value;
        }
        else {
            $log->debug("setAttrs() : No parameter named '$name' for ". ref($self));
        }
    }
}

# get : retrieve one instance from an id

sub get {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);

    my $table = _buildClassName($class);
    my $adm = Administrator->new();

    my $dbix = $adm->getRow(id=>$args{id}, table => $table);
    $log->debug("Named arguments: id = <$args{id}> , table = <$table>");

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

    my $type = _buildClassName($class)
    my $adm = Administrator->new();
    
    my $rs = $adm->_getDbixFromHash( table => $type, hash => $args{hash} );

    $log->debug( "Search with type = $type");
    
    my $id_name = lc($type) . "_id";

    while ( my $row = $rs->next ) {
        my $id = $row->get_column($id_name);
        my $obj = eval { $class->get(id => $id); };
        if($@) {
            my $exception = $@; 
            if(Kanopya::Exception::Permission::Denied->caught()) {
                $log->info("no right to access to object <$args{type}> with  <$id>");
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
    
}

# delete : remove records from the entire class hierarchy

sub delete {
    
}
