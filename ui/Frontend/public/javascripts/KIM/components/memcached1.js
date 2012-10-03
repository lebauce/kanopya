require('KIM/component.js');

var Memcached1 = (function(_super) {
    Memcached1.prototype = new _super();

    function Memcached1(id) {
        _super.call(this, id);

        this.displayed = [ 'php5_session_handler','php5_session_path' ];
        this.relations = {};
    };

    return Memcached1;

})(Component);
