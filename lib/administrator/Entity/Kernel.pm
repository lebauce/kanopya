# Kernel.pm - This object allows to manipulate Kernel configuration
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
# Created 7 july 2010
package Entity::Kernel;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use General;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    kernel_name => { pattern => '^.*$', is_mandatory => 1, is_extended => 0 },
    kernel_version => { pattern => '^.*$', is_mandatory => 1, is_extended => 0 },
    kernel_desc => { pattern => '^.*$', is_mandatory => 0, is_extended => 0 },

};

sub methods {    
    return {
        'get'        => {'description' => 'view this kernel', 
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this kernel', 
                        'perm_holder' => 'entity',
        },
    };
}

=head2 get

=cut

sub get {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['id']);
    
    my $admin = Administrator->new();
       my $dbix_kernel = $admin->{db}->resultset('Kernel')->find($args{id});
       if(not defined $dbix_kernel) {
           $errmsg = "Entity::Kernel->get : id <$args{id}> not found !";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
       } 
       my $entity_id = $dbix_kernel->entitylink->get_column('entity_id');
       my $granted = $admin->{_rightchecker}->checkPerm(entity_id => $entity_id, method => 'get');
       if(not $granted) {
           throw Kanopya::Exception::Permission::Denied(error => "Permission denied to get kernel with id $args{id}");
       }
    
   my $self = $class->SUPER::get( %args,  table => "Kernel");
   return $self;
}

=head2 getKernels

=cut

sub getKernels {
    my $class = shift;
    my %args = @_;
    my @objs = ();
    my ($rs, $entity_class);

    General::checkParams(args => \%args, required => ['hash']);

    my $adm = Administrator->new();
    return $class->SUPER::getEntities( %args,  type => "Kernel");
}

=head2 new

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # Check attrs ad throw exception if attrs missed or incorrect
    my $attrs = $class->checkAttrs(attrs => \%args);
    
    # We create a new DBIx containing new entity (only global attrs)
    my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Kernel");
    
    # Set the extended parameters
    $self->{_ext_attrs} = $attrs->{extended};

    return $self;

}

=head2 remove

=cut

sub remove {}

sub getAttrDef{
    return ATTR_DEF;
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('kernel_name');
    return $string;
}

1;
