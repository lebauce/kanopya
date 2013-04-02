require('KIM/component.js');

var Kanopyaexecutor = (function(_super) {
    Kanopyaexecutor.prototype = new _super();

    function Kanopyaexecutor(id) {
        _super.call(this, id);

        this.displayed = [ 'time_step', 'masterimages_directory', 'clusters_directory' ];
    };

    return Kanopyaexecutor;

})(Component);
