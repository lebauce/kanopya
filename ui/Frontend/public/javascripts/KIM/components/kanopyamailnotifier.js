require('KIM/component.js');

var KanopyaMailNotifier = (function(_super) {
    KanopyaMailNotifier.prototype = new _super();

    function KanopyaMailNotifier(id) {
        _super.call(this, id);

        this.displayed = [ 'smtp_server', 'smtp_login', 'smtp_passwd', 'use_ssl'];
        this.relations = {};
    };

    return KanopyaMailNotifier;

})(Component);
