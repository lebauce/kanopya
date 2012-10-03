require('KIM/component.js');

var Puppetmaster2 = (function(_super) {
    Puppetmaster2.prototype = new _super();

    function Puppetmaster2(id) {
        _super.call(this, id);

        this.displayed = [ 'puppetmaster2_options' ];
        this.relations = {};
    };

    return Puppetmaster2;

})(Component);
