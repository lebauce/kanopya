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
use Operation;
use General;

use Entity::Container;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
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
};

sub getAttrDef { return ATTR_DEF; }

sub methods {
    return {
        'upload'    => {'description' => 'upload a new master image', 
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this master image', 
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this master image', 
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this master image', 
                        'perm_holder' => 'entity',
        },
    };
}

=head2 getMasterimages

    Class: public
    desc: retrieve several Entity::Masterimage instances
    args:
        hash : hashref : where criteria
    return: @ : array of Entity::Masterimage instances
    
=cut

sub getMasterimages {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

sub getMasterimage {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    my @masterimages = $class->search(%args);
    return pop @masterimages;
}

=head2 remove

=cut

sub remove {
    my $self = shift;
    my $id = $self->getAttr(name=> 'masterimage_id');
    
    $log->debug("New Operation RemoveMasterimage with masterimage_id : <".$id.">");
    Operation->enqueue(
        priority => 200,
        type     => 'RemoveMasterimage',
        params   => {masterimage_id => $id},
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

=head getProvidedComponents

get components already installed on this master image
return array ref containing hash ref 

=cut

sub getProvidedComponents {
    my $self = shift;
    if(! $self->{_dbix}->in_storage) {
        $errmsg = "Entity::Masterimages->getProvidedComponents must be called on an already save instance";
        $log->error($errmsg);
        throw Kanopya::Exception(error => $errmsg);
    }
    my $components = [];
    my $search = $self->{_dbix}->components_provided->search(undef, 
        { '+columns' => {'component_name' => 'component_type.component_name', 
                         'component_version' => 'component_type.component_version', 
                         'component_category' => 'component_type.component_category' },
            join => ['component_type'] } 
    );
    while (my $row = $search->next) {
        my $tmp = {};
        $tmp->{component_type_id} = $row->get_column('component_type_id');
        $tmp->{component_name} = $row->get_column('component_name');
        $tmp->{component_version} = $row->get_column('component_version');
        $tmp->{component_category} = $row->get_column('component_category');
        push @$components, $tmp;
    }
    return $components;
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
