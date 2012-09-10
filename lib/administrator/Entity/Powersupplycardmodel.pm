# Powersupplycardmodel.pm - This object allows to manipulate Powersupplycard model
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
# Created 17 july 2010
package Entity::Powersupplycardmodel;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;
use Administrator;
use General;
use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    powersupplycardmodel_name => { pattern => 'm/\w*/s',
                          is_mandatory => 1,
                          is_extended => 0 },
    
    powersupplycardmodel_brand => { pattern => 'm/\w*/s',
                          is_mandatory => 1,
                          is_extended => 0 },
    
    powersupplycardmodel_slotscount => { pattern => 'm//s',
                         is_mandatory => 1,
                         is_extended => 0 },
};


sub methods {
    return {
        'create'    => {'description' => 'create a new powersupply card model', 
                        'perm_holder' => 'mastergroup',
        },
        'get'        => {'description' => 'view this powersupply card model', 
                        'perm_holder' => 'entity',
        },
        'update'    => {'description' => 'save changes applied on this powersupply card model', 
                        'perm_holder' => 'entity',
        },
        'remove'    => {'description' => 'delete this powersupply card model', 
                        'perm_holder' => 'entity',
        },
        'setperm'    => {'description' => 'set permissions on this powersupply card model', 
                        'perm_holder' => 'entity',
        },
    }; 
}

sub getPowersupplycardmodels {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

=head2 create

=cut

sub create {
    my $self = shift;
       
    $self->save();
}

=head2 update

=cut

sub update {}

=head2 remove

=cut 

sub remove {
    my $self = shift;

    $self->SUPER::delete();
}

sub getAttrDef{
    return ATTR_DEF;
}

sub extension { return; }

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('powersupplycardmodel_brand')." ".$self->{_dbix}->get_column('powersupplycardmodel_name');
    return $string;
}

1;
