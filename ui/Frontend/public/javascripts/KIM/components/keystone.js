require('KIM/component.js');

var Keystone = (function(_super) {
    Keystone.prototype = new _super();

    function Keystone(id) {
        _super.call(this, id);

        this.displayed = [ 'mysql5_id' ];
        this.relations = {};
    };

    return Keystone;

})(Component);
