package AdministratorDB::EntityBase;
use base qw(DBIx::Class);

# DEPRECATED géré au niveau des classes Entity
sub extended_table {
	
	# pour l'instant c'est les classes dérivées (ex Shema:::Motherboard) qui doivent redefinir cette fonction pour préciser la table
	# on pourra mettre ici un comportement générique si la clé étrangère vers la table a un format défini (ex: motherboard_ext )
	
	return undef;
} 

1;