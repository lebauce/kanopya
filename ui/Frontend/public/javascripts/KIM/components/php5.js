require('KIM/component.js');

var Php5 = (function(_super) {
    Php5.prototype = new _super();

    function Php5(id) {
        _super.call(this, id);

        this.displayed = [ 'php5_session_handler','php5_session_path' ];
        this.relations = {};
    };

    return Php5;

})(Component);
