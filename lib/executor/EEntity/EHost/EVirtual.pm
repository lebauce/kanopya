# EVirtual.pm - class of virtual EHosts object

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
# Created 20 nov 2011

=head1 NAME

EVirtual - execution class of virtual host entities

=head1 SYNOPSIS



=head1 DESCRIPTION

EHost::EVirtual is the execution class for virtual host entities

=head1 METHODS

=cut
package EEntity::EHost::EVirtual;
use base "EEntity::EHost";

sub new {
    my $class = shift;
    my %args = @_;
    
    my $virtual_comp = $args{virt_comp};
    delete $args{virt_comp};
    my $self = $class->SUPER::new(%args);
    $self->{virtual_component} = $virtual_comp;
    
    return $self;
}

sub start{
    
}

sub stop {
    
}
1;