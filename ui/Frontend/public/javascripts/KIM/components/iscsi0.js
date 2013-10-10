require('KIM/component.js');

var Iscsi = (function(_super) {
    Iscsi.prototype = new _super();

    function Iscsi(id) {
        _super.call(this, id);

        this.displayed = [];
        this.relations = {
            'iscsi_portals' : [ 'iscsi_portal_ip', 'iscsi_portal_port' ]
        };
    };
    return Iscsi;

})(Component);
