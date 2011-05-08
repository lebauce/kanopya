# Message.pm - This object allows to manipulate Message with user interface
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
# Created 3 sept 2010
package Entity::Message;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("administrator");
my $errmsg;

use constant ATTR_DEF => {
    user_id => {pattern => 'm//s', is_mandatory => 0, is_extended => 0},
    message_type => {pattern => 'm//s', is_mandatory => 1, is_extended => 0},
    message_content => {pattern => 'm//s', is_mandatory => 1, is_extended => 0},
    message_creationdate => {pattern => 'm//s', is_mandatory => 0, is_extended => 0},
};

sub get {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{id} or ! defined $args{id})) { 
        $errmsg = "Entity::Message->new need an id named argument!";    
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
   my $self = $class->SUPER::get( %args,  table => "Message");
   return $self;
}

sub getMessages {
    my $class = shift;
    my %args = @_;
    my @objs = ();
    my ($rs, $entity_class);

    if ((! exists $args{hash} or ! defined $args{hash})) { 
        $errmsg = "Entity::getMessages need a type and a hash named argument!";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $adm = Administrator->new();
       return $class->SUPER::getEntities( %args,  type => "Message");
}

sub new {
    my $class = shift;
    my %args = @_;

    # Check attrs ad throw exception if attrs missed or incorrect
    my $attrs = $class->checkAttrs(attrs => \%args);
    
    # We create a new DBIx containing new entity (only global attrs)
    my $self = $class->SUPER::new( attrs => $attrs->{global},  table => "Message");
    
    # Set the extended parameters
    $self->{_ext_attrs} = $attrs->{extended};

    return $self;

}

sub extension { return undef; }

sub save {
    my $self = shift;
    $self->{_dbix}->set_column({'message_creationdate' => \"> CURRENT_DATE()"});
    $self->SUPER::save($self);
}

sub getAttrDef{
    return ATTR_DEF;
}



1;