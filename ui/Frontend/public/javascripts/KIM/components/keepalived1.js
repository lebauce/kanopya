require('KIM/component.js');

var Keepalived1 = (function(_super) {
    Keepalived1.prototype = new _super();

    function Keepalived1(id) {
        _super.call(this, id);

        this.displayed = ['notification_email', 'smtp_server'];
        this.relations = {
            'keepalived1_vrrpinstances' : ['vrrpinstance_name', 'vrrpinstance_password', 'interface_id', 'virtualip_interface_id', 'virtualip_id']
        };
    };

    return Keepalived1;

})(Component);
