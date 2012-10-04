require('KIM/component.js');

var Puppetagent2 = (function(_super) {
    Puppetagent2.prototype = new _super();

    function Puppetagent2(id) {
        _super.call(this, id);

        this.displayed = [ 'puppetagent2_mode', 'puppetagent2_masterip', 'puppetagent2_masterfqdn', 'puppetagent2_options' ];
        this.relations = {};
    };

    return Puppetagent2;

})(Component);
