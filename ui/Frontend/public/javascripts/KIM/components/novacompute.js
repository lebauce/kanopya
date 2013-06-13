require('KIM/component.js');

var Novacompute = (function(_super) {
    Novacompute.prototype = new _super();

    function Novacompute(id) {
        _super.call(this, id);

        this.displayed = [ 'iaas_id' ];
        this.relations = {};
    };

    return Novacompute;

})(Component);
