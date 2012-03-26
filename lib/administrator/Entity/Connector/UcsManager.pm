#    UCSManager.pm - Cisco UCS connector
#    Copyright © 2012 Hedera Technology SAS
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

package Entity::Connector::UcsManager;
use base "Entity::Connector";
use base "Entity::HostManager";

use warnings;

use Cisco::UCS;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub getBootPolicies { return ('BootOnSan');  }

sub getHostType {
    return "UCS blade";
}

sub get {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::get(%args);

    my $ucs = Entity::ServiceProvider::Outside::UnifiedComputingSystem->get(
                  id => $self->getAttr(name => "service_provider_id")
              );

    $self->{api} = Cisco::UCS->new(
                       proto    => "http",
                       port     => 80,
                       cluster  => $ucs->getAttr(name => "ucs_addr"),
                       username => $ucs->getAttr(name => "ucs_login"),
                       passwd   => $ucs->getAttr(name => "ucs_passwd")
                   );

    $self->{state} = ($self->{api}->login() ? "up" : "down");

    $self->{ou} = $ucs->getAttr(name => "ucs_ou");

    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $method = $autoload[-1];

    return $self->{api}->$method(%args);
}

sub DESTROY {
    my $self = shift;

    if (defined $self->{api}) {
        $self->{api}->logout();
        $self->{api} = undef;
    }
}

1;
