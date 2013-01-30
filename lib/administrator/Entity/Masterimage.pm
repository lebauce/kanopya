# Masterimage.pm - This object allows to manipulate Master image configuration
#    Copyright 2011 Hedera Technology SAS
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
# Created 17 july 2010

package Entity::Masterimage;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use Entity::Operation;
use General;

use Entity::Container;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    masterimage_name => {
        pattern      => '^.+$',
        is_mandatory => 1,
    },
    masterimage_file => {
        pattern      => '^.+$',
        is_mandatory => 1,
    },
    masterimage_desc => {
        pattern      => '^.*$',
        is_mandatory => 0,
    },
    masterimage_os => {
        pattern      => '^.+$',
        is_mandatory => 0,
    },
    masterimage_size => {
        pattern      => '^[0-9]+$',
        is_mandatory => 1,
    },
    masterimage_defaultkernel_id => {
        pattern      => '^[0-9]*$',
        is_mandatory => 0
    }
};

sub getAttrDef { return ATTR_DEF; }

=head2 create

=cut

sub create {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'file_path' ]);

    Entity::Operation->enqueue(
        priority    => 200,
        type        => 'DeployMasterimage',
        params      => {
            file_path   => $args{file_path}
        }
    );
}

=head2 remove

=cut

sub remove {
    my $self = shift;
    my $id = $self->getAttr(name=> 'masterimage_id');
    
    $log->debug("New Operation RemoveMasterimage with masterimage_id : <".$id.">");
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'RemoveMasterimage',
        params  => {
            context => {
                masterimage => $self
            }
        },
    );
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('masterimage_name');
    return $string;
}

=head setProvidedComponent

specify a component as installed on this master image

=cut

sub setProvidedComponent {
    my $self = shift;
    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Masterimages->setProvidedComponent must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    
    my %args = @_;
    
    General::checkParams(args => \%args, required => ['component_name', 'component_version']);
    
    my $adm = Administrator->new;
    my $component = $adm->{db}->resultset('ComponentType')->search({
        component_name    => $args{component_name},
        component_version => $args{component_version},
    })->single;
    
    if(defined $component) {
        $self->{_dbix}->components_provided->find_or_create({
            component_type_id => $component->get_column('component_type_id')
        });
    }
}

1;
