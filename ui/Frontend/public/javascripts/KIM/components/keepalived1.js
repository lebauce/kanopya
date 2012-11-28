require('KIM/component.js');

var Keepalived1 = (function(_super) {
    Keepalived1.prototype = new _super();

    function Keepalived1(id) {
        _super.call(this, id);

        this.displayed = [ 'notification_email', 'notification_email_from', 'smtp_server',
                           'smtp_connect_timeout', 'daemon_method'];
        this.relations = {};
    };

    return Keepalived1;

})(Component);
