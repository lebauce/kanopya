require('KIM/component.js');

var Haproxy = (function(_super) {
    Haproxy.prototype = new _super();

    function Haproxy(id) {
        _super.call(this, id);

        this.displayed = [ ];
        this.relations = {
                'haproxy1s_listen' : ['listen_name', 'listen_ip', 'listen_port', 'listen_mode', 'listen_balance', 'listen_component_id', 'listen_component_port']
        };
    };

    return Haproxy;

})(Component);
