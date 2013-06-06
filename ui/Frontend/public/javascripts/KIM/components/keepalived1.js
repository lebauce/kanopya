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

    Keepalived1.prototype.optionsCallback = function(name, value, relations) {
        // We want only list interfaces of the associated service provider
        if (name == 'interface_id' || name == 'virtualip_interface_id') {
            var options = ajax('GET', '/api/component/' + this.id + '/service_provider/interfaces');
            return options;
        }
        return false;
    };

    return Keepalived1;

})(Component);
