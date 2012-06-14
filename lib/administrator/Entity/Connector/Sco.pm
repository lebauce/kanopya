# Scom.pm - SCOM connector
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
# Created 5 june 2012

package Entity::Connector::Sco;
use base 'Entity::Connector';
use base 'Manager::WorkflowManager';

use strict;
use warnings;
use General;
use Kanopya::Exceptions;

use ScopeParameter;
use Scope;
use Workflow;
use WorkflowDef;
use WorkflowDefManager;
use Entity::ServiceProvider;

use Data::Dumper;
use Log::Log4perl 'get_logger';
my $log = get_logger('administrator');
my $errmsg;

use constant ATTR_DEF => {};
sub getAttrDef { return ATTR_DEF; }
 
=head2 _prepareParams
    Desc: Retrieve the list of effective parameters desired by the user in the
          final file 

    Args: \%brut_data_params

    Return: \%prepared_data_params 
=cut

sub _prepareParams {
    my ($self,%args) = @_;
    
    General::checkParams(args => \%args, required => [ 'data_params' ]);
    
    my $data_params      = $args{data_params};
    my $template_content = $data_params->{template_content};
    my %prepared_data_params;

    #print Dumper $template_content;
    my @lines            = split (/\n/, $template_content);

    foreach my $line (@lines) {
        my @split = split(/\[\% | \%\]/, $line);
        for (my $i = 1; $i < (scalar @split); $i+=2){
            $prepared_data_params{$split[$i]} = undef;
        }
    }
    #print Dumper \%prepared_data_params;

    return \%prepared_data_params;
}
1;
