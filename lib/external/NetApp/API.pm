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

package NetApp::API;

use NaServer;
use NaElement;
use NaObject;

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self , $class;

    $self->{username} = $args{username};
    $self->{passwd} = $args{passwd};

    $self->{server} = NaServer->new($args{addr}, 1, 3);
    $self->{server}->set_debug_style("NA_NO_DEBUG");

    $self->login();

    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $method = $autoload[-1];
    $method =~ s/_/-/g;

    my $request = NaElement->new($method);
    foreach my $key (keys %args) {
        $request->child_add_string($key, $args{$key});
    }

    my $response = $self->{server}->invoke_elem($request);
    if ($response->results_status() eq "failed") {
        print "NetApp error : " . $response->results_reason() . "\n";
        exit (-2);
    }

    bless $response, "NaObject";
    return $response;
}

sub DESTROY {
}

sub login {
	my $self = shift;

	my $response = $self->{server}->set_style(LOGIN);
	if (ref ($response) eq "NaElement" && $response->results_errno != 0) {
		my $r = $response->results_reason();
		print "Unable to set authentication style $r\n";
		exit 2;
	}
	$self->{server}->set_admin_user($self->{username}, $self->{passwd});
	$response = $self->{server}->set_transport_type(HTTP);
}

sub logout {
}

sub aggregates {
	my $self = shift;

    my @objs = ();
    my @aggregates = $self->aggr_list_info()->child_get("aggregates")->children_get();
    foreach $aggr (@aggregates) {
        push @objs, bless $aggr, "NaObject";
    }
    return @objs;
}

sub luns {
	my $self = shift;

    my @objs = ();
    my @luns = $self->lun_list_info()->child_get("luns")->children_get();
    foreach $lun (@luns) {
        push @objs, bless $lun, "NaObject";
    }
    return @objs;
}

sub volumes {
	my $self = shift;

    my @objs = ();
    my @volumes = $self->volume_list_info()->child_get("volumes")->children_get();
    foreach $volume (@volumes) {
        push @objs, bless $volume, "NaObject";
    }
    return @objs;
}

sub disks {
	my $self = shift;

    my @objs = ();
    my @volumes = $self->disk_list_info()->child_get("disk-details")->children_get();
    foreach $volume (@volumes) {
        push @objs, bless $volume, "NaObject";
    }
    return @objs;
}

1;
