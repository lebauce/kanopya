require('KIM/component.js');

var Mailnotifier0 = (function(_super) {
    Mailnotifier0.prototype = new _super();

    function Mailnotifier0(id) {
        _super.call(this, id);

        this.displayed = [ 'smtp_server', 'smtp_login', 'smtp_passwd', 'use_ssl'];
        this.relations = {};
    };

    return Mailnotifier0;

})(Component);
