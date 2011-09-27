package Distributions;

use Dancer ':syntax';

use Entity::Systemimage;
use Entity::Distribution;

sub _systemimages {

    my @esystemimages = Entity::Systemimage->getSystemimages(hash => {});
    my $systemimages = [];

    foreach my $s (@esystemimages) {
        my $tmp = {};
        $tmp->{systemimage_id}   = $s->getAttr(name => 'systemimage_id');
        $tmp->{systemimage_name} = $s->getAttr(name => 'systemimage_name');
        $tmp->{systemimage_desc} = $s->getAttr(name => 'systemimage_desc');

        eval {
            my $edistro = Entity::Distribution->get(id => $s->getAttr(name => 'distribution_id'));
            $tmp->{distribution} = $edistro->getAttr(name =>'distribution_name')." ".$edistro->getAttr(name => 'distribution_version');
        };

        $tmp->{active} = $s->getAttr(name => 'active');
        if($tmp->{active}) {
            $tmp->{systemimage_usage} = $s->getAttr(name => 'systemimage_dedicated') ? 'dedicated' : 'shared';
        } else {
            $tmp->{systemimage_usage} = '';
        }
        push (@$systemimages, $tmp);
    }

    return $systemimages;
}

get '/images' => sub {

    my $can_create;
    my $methods = Entity::Systemimage->getPerms();
    if($methods->{'create'}->{'granted'}) { $can_create = 1 }

    my @edistros = Entity::Distribution->getDistributions(hash => {});
    if(not scalar(@edistros)) { $can_create = 0 }

    template 'images', {
        title_page         => 'Systems - System images',
        distributions_list => _systemimages(),
        can_create         => $can_create,
    }
}

