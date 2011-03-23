# Interface for a model that predict quality of service of and internet service

package Model;

use strict;
use warnings;
use Kanopya::Exceptions;


=head2 calculate
	
	Class : Public virtual (must be implemented by child)
	
	Desc : 	Interface for calculating the quality of the Internet service
	 		(e.g. performance, availability, cost, etc.)
	 		according to underlying system configuration, workload characteristics and workload amount
	
	Args :
	
	Return :
	
=cut

sub calculate {
	my $self = shift;
	throw Kanopya::Exception::Internal(error => "Model interface method not implemented by " . ref $self);
}


1;