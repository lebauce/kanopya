# base class to manage inheritance throw relational database

package BaseDB;


# _buildAttrsHierarchy : given a flat attributes hash ref, build 
# attrs hash ref with correct class hierarchy to call 
# result('concrettable')->new($hash)

sub _buildAttrsHierarchy {
	
}

# à voir si on garde

sub getExtendedAttrs  {}

# checkAttrs : check attribute(s) validity in the class hierarchy 
# return attrs hash ref with correct class hierarchy to class 
# result('concrettable')->new($hash)

sub checkAttrs {
	
}

# new : return dbix resultset with full class hierarchy of this 

sub new {
	
}

# getAttr : retrieve a value given a name attribute ; search this
# atribute throw the whole class hierarchy

sub getAttr {

}

# setAttr : set one (or several) name attribute with the given value ;
# search this (these) attribute throw the whole class hierarchy, 
# and check attribute validity

sub setAttrs {

}

# get : retrive one instance from an id

sub get {
	
}

# search : retrieve several instance via a hash ref filter 

sub search {
	
}

# save : store records in database ;
# create them in not exists, update them otherwise

sub save {
	
}

# delete : remove records from the entire class hierarchy

sub delete {
	
}
