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

use JSON;
use Hash::Merge;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    params => {
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

    # Delete possible 'name' argument for code compatibility
    delete $args{name};

    my $self = $class->SUPER::new(%args);

    if (defined $params and keys %$params) {
        $self->update(params => $params);
    }

    return $self;
}

sub load {
    my $self = shift;
    my %args = @_;

    my $result;
    eval {
        $result = from_json($self->params);
    };
    if ($@) {
        return {};
    }
    return $result;
}

sub store {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    $self->setAttr(name => 'params', value => to_json($args{params}));
    $self->save();
}

sub update {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'params' ]);

    my $existing = {};
    if (not $args{override}) {
        $existing = $self->load();
    }

    my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
    $existing = $merge->merge($existing, $args{params});

    $self->store(params => $existing);
}

1;
