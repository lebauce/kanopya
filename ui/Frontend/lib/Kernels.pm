package Kernels;

use Dancer ':syntax';

use Entity::Kernel;

# kernels listing page

sub _view_kernels {

    my @ekernels = Entity::Kernel->getKernels(hash => {});
    my $kernels = [];

    foreach my $m (@ekernels) {
        my $tmp      = {};
        my $methods  = $m->getPerms();

        $tmp->{kernel_id}      = $m->getAttr(name => 'kernel_id');
        $tmp->{kernel_name}    = $m->getAttr(name => 'kernel_name');
        $tmp->{kernel_version} = $m->getAttr(name => 'kernel_version');
        $tmp->{kernel_desc}    = $m->getAttr(name => 'kernel_desc');
        $tmp->{can_setperm}    = 1 if ( $methods->{'setperm'}->{'granted'} );

        push (@$kernels, $tmp);
    }

    return $kernels;
}

get "/kernels" => sub {

    my $methods     = Entity::Kernel->getPerms();
    my $link_upload = $methods->{'upload'}->{'granted'} ? 1 : 0;

    template 'kernel', {
        kernels_list => _view_kernels(),
        titlepage    => 'Systems - Kernels',
        username     => session('username'),
        link_upload  => $link_upload,
    };
}


1;
