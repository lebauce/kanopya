# Connector.pm Base class for connector
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
# Created 24 july 2010

package Entity::Connector;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");


use constant ATTR_DEF => {
    connector_type_id => {  pattern        => '\d*',
                            is_mandatory   => 1,
                            is_extended    => 0,
                            is_editable    => 0
                         },
    service_provider_id => {
      pattern       => '^\d*$',
      is_mandatory  => 1,
      is_extended   => 0,
      is_editable   => 0
    }
};

sub getAttrDef { return ATTR_DEF; }

sub new {
    my $class = shift;
    my %args = @_;
    
    # avoid abstract Entity::Connector instanciation
    if($class !~ /Entity::Connector::(.+)/) {
        my $errmsg = "Entity::Connector must not be instanciated without a concret connector class";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
    my $connector_name    = $1;

    # we set the corresponding connector_type
    my $admin = Administrator->new();
    my $connector_type = $admin->{db}->resultset('ConnectorType')->search(
        { connector_name    => $connector_name }
    )->single;
    
    if (not defined $connector_type) {
        throw Kanopya::Exception::Internal(error => "Connector type $connector_name not found in DB");
    }
    my $connector_type_id = $connector_type->id;
    
    return $class->SUPER::new(%args, connector_type_id => $connector_type_id );
}

sub getConnectorTypes {
    my $admin = Administrator->new();
    
    my $connectortype_rs = $admin->{db}->resultset('ConnectorType');
    
    my @connector_types;
    while (my $ct = $connectortype_rs->next) {
        push @connector_types, {
            connector_type_id   => $ct->connector_type_id,
            connector_name      => $ct->connector_name,
            connector_category  => $ct->connector_category,
        } 
    }

    return \@connector_types;
}

sub getConnectorType {
    my $self = shift;
    
    my $admin = Administrator->new();
    my $connector_type = $admin->{db}->resultset('ConnectorType')->search(
        { connector_type_id  => $self->getAttr( name => 'connector_type_id') }
    )->single;

    return {
        connector_name => $connector_type->connector_name,
        connector_category => $connector_type->connector_category,
    };

}

=head2 getHostingPolicyParams

=cut

sub getPolicyParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'policy_type' ]);

    return [];
}

=head2 getServiceProvider

    Desc: Returns the service provider the component is on

=cut

sub getServiceProvider {
    my $self = shift;

    return Entity->get(id => $self->getAttr(name => "service_provider_id"));
}

sub getConf {
    my $self = shift;

    my %row = $self->{_dbix}->get_columns(); 

    return \%row;
}

sub setConf {
    my $self = shift;
    my ($conf) = @_;

    # update, assuming row is created when connector new
    $self->{_dbix}->update( $conf );
}

=head2 checkConf

    Can be implemented by concrete connector
    Allow to check configuration (connection, data retrieving)
    Return a result message or throw exception if error

=cut

sub checkConf {
    my $self = shift;
    
    throw Kanopya::Exception::Internal(error => "Check not implemented for " . (ref $self));
}

1;
