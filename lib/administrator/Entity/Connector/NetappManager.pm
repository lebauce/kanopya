#    NetappManager.pm - NetApp connector
#    Copyright © 2012 Hedera Technology SAS
#
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

package Entity::Connector::NetappManager;
use base "Entity::Connector";
use lib "/opt/kanopya/lib/external/NetApp";

use warnings;
use NetApp::API;

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

sub get {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::get(%args);

    my $netapp = Entity::ServiceProvider::Outside::Netapp->get(
                     id => $self->getAttr(name => "outside_id")
                 );

    $self->{api} = NetApp::API->new(
                       addr     => $netapp->getAttr(name => "netapp_addr"),
                       username => $netapp->getAttr(name => "netapp_login"),
                       passwd   => $netapp->getAttr(name => "netapp_passwd")
                   );

    eval {
        $self->system_get_version();
        $self->{state} = "up";
    };
    if ($@) {
        $self->{state} = "down";
    }

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
    if (defined $self->{api}) {
        $self->{api}->logout();
        $self->{api} = undef;
    }
}

sub startHost {
    my $self = shift;
    my %args = @_;

#    General::checkParams(args => \%args, required => [ "cluster", "host" ]);
}

sub postStart {
}

sub stopHost {
    my $self = shift;
    my %args = @_;

#    General::checkParams(args => \%args, required => [ "cluster", "host" ]);

#    my $sn = $args{host}->getAttr(name => "host_serial_number");
#    $self->{api}->stop_service_profile(dn => $self->{ou} . "/" . $sn);
}

1;
