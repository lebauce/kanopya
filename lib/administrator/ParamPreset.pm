# Copyright © 2011-2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package ParamPreset;
use base 'BaseDB';

use strict;
use warnings;

use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');
my $errmsg;

use constant ATTR_DEF => {
    name => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    value => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
    relation => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my $class = shift;
    my %args = @_;

    my $params;
    if (defined $args{params}) {
        $params = delete $args{params};
    }

    my $self = $class->SUPER::new(%args);

    if (defined $params) {
        $self->update(params => $params);
    }

    return $self;
}

sub load {
    my $self = shift;
    my %args = @_;

    my $result;
    my $childs = $self->{_dbix}->param_presets;
    eval {
        while (my $current = $childs->next) {
            # If current item has param_preset relation, build the related sub hash or list.
            if ($current->param_presets->count) {
                my $param_preset = ParamPreset->get(id => $current->get_column('param_preset_id'));
                $result->{$current->get_column('name')} = $param_preset->load();
            }
            # If current item has a name defined, the runnning function will return a hash
            elsif ($current->get_column('name')) {
                $result->{$current->get_column('name')} = $current->get_column('value');
            }
            # If current item has no name defined, the runnning function will return a list
            else {
                push @$result, $current->get_column('value');
            }
        }
    };
    if ($@) {
        my $preset_id = $self->getAttr(name => 'param_preset_id');
        throw Kanopya::Exception::Internal(
                  error => "Unable to load preset <$preset_id> from database, you have probably mixed " .
                           "hash elements and list elements within a same relation level:\n$@"
              );
    }
    return $result ? $result : {};
}

sub store {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    my @tostore;
    for my $name (keys %{$args{params}}) {
        my $preset;
        $preset->{name} = $name;
        if (ref($args{params}->{$name}) eq 'HASH') {
            $preset->{param_presets} = $self->store(params => $args{params}->{$name}, nopopulate => 1);
        }
        elsif (ref($args{params}->{$name}) eq 'ARRAY') {
            # In this mechnism for storing hashes, lists can be stored at the last level only.
            # This is because Hash::Merge module is able to proper merge list values, but its
            # can not merge hashes within list elements.
            $preset->{param_presets} = [];
            for my $item (@{ $args{params}->{$name} }) {
                push @{ $preset->{param_presets} }, { value => $item };
            }
        }
        else {
            $preset->{value} = $args{params}->{$name};
        }
        push @tostore, $preset;
    }

    if ($args{nopopulate}) {
        return \@tostore;
    }
    $self->{_dbix}->param_presets->populate(\@tostore);
}

sub update {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    my $existing = $self->load();

    # Remove existing childs before insert the new ones marged with args.
    my @childs = ParamPreset->search(hash => { relation => $self->getAttr(name => 'param_preset_id') });
    for my $child (@childs) {
        $child->delete();
    }

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
    $existing = $merge->merge($existing, $args{params});

    $self->store(params => $existing);
}

1;
