require('KIM/component.js');

var Novacompute = (function(_super) {
    Novacompute.prototype = new _super();

    function Novacompute(id) {
        _super.call(this, id);

        this.displayed = [ 'mysql5_id', 'nova_controller_id' ];
        this.relations = {};
    };

    return Novacompute;

})(Component);
