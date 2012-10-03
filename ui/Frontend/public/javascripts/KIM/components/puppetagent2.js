require('KIM/component.js');

var Puppetaggent2 = (function(_super) {
    Puppetaggent2.prototype = new _super();

    function Puppetaggent2(id) {
        _super.call(this, id);

        this.displayed = [ 'puppetagent2_mode', 'puppetagent2_masterip', 'puppetagent2_masterfqdn', 'puppetagent2_options' ];
        this.relations = {};
    };

    return Puppetaggent2;

})(Component);
