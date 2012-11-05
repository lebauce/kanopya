require('KIM/component.js');

var Linux0 = (function(_super) {
    Linux0.prototype = new _super();

    function Linux0(id) {
        _super.call(this, id);

        this.displayed = [];
        this.relations = {
            'linux0s_mount': [ 'linux0_mount_device', 'linux0_mount_point', 'linux0_mount_filesystem',
                               'linux0_mount_options', 'linux0_mount_dumpfreq', 'linux0_mount_passnum' ],
        }
    };

    return Linux0;

})(Component);
