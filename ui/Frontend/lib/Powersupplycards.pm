package Powersupplycards;

use Dancer ':syntax';
use Entity::Powersupplycard;
use Entity::Powersupplycardmodel;

prefix '/infrastructures';

sub _powersupplycards {

    my @powersupplycards = Entity::Powersupplycard->getPowerSupplyCards(hash => {});
    my $pscs = [];

    foreach my $psc (@powersupplycards) {
        my $tmp = {};
        $tmp->{powersupplycard_id} = $psc->getAttr(name => 'powersupplycard_id');
        $tmp->{powersupplycard_name} = $psc->getAttr(name => 'powersupplycard_name');
        $tmp->{powersupplycard_desc} = "Ajouter le champ description dans la database!"; 
        $tmp->{powersupplycard_ip} = $psc->getAttr(name => 'powersupplycard_ip');
        $tmp->{active} = $psc->getAttr(name => 'active');
        push @$pscs, $tmp;
    }

    return $pscs;
}

sub _powersupply_card_details {
    my $id = @_;

    my $epowersupplycard = Entity::Powersupplycard->get(id => $id));

    my $model = Entity::Powersupplycardmodel->get(id => $epowersupplycard->getAttr(name => 'powersupplycardmodel_id'));

    my $active = $epowersupplycard->getAttr(name => 'active'));
    my $model = $model->toString());
    my $slots_count = $model->getAttr(name => 'powersupplycardmodel_slotscount'));
    my $powersupplycard_name = $epowersupplycard->getAttr(name => 'powersupplycard_name'));
    my $powersupplycard_desc = 'ajouter la description dans la database!!!');
    my $mac_address = $epowersupplycard->getAttr(name => 'powersupplycard_mac_address'));
    my $ip = $epowersupplycard->getAttr(name => 'powersupplycard_ip'));

    return ($active,$model,$slots_count,$powersupplycard_name,$powersupplycard_desc,$mac_address,$ip);
}
     # header / menu variables
    $tmpl->param('titlepage' => "");
    $tmpl->param('mHardware' => 1);
    $tmpl->param('submPower' => 1);
    $tmpl->param('username' => $self->session->param('username'));

get '/powersupply' => sub {
    my $can_create;
    my $methods = Entity::Powersupplycard->getPerms();
    if($methods->{'create'}->{'granted'}) { $can_create = 1 }
    template 'powersupply' {
          titlepage => "Hardware - Powersupplycards",
          can_create => $can_create,
    };
};

get '/powersupply/:id' => sub {
    my ($active,$model,$slots_count,$powersupplycard_name,$powersupplycard_desc,$mac_address,$ip) = _powersupply_card_details(params->{id});
    template 'powersupply' {
          titlepage => "Power supply card's overview",
          can_create => $can_create,
          active => $active,
          model => $model,    
          slots_count => $slots_count,
          powersupplycard_name => $powersupplycard_name,
          powersupplycard_desc => $powersupplycard_desc,
          mac_address => $mac_address,
          ip => $ip,
    };
};
