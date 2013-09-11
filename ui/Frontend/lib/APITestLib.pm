package APITestLib;

use Frontend;
use Dancer::Test;

use Kanopya::Exceptions;


sub login {
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'login' => 'admin', 'password' => 'K4n0pY4' });

    my $response = dancer_response(POST => '/login', { params => { login => $args{login}, password => $args{password} } });

    if ($response->{status} != 302) {
        $errmsg = "Authentication failed for login " . $args{login};
        throw Kanopya::Exception::AuthenticationFailed(error => $errmsg);
    }
}

1;