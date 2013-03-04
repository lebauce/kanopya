require('KIM/component.js');

var Linux0 = (function(_super) {
    Linux0.prototype = new _super();

    function Linux0(id) {
        _super.call(this, id);

        this.displayed = [];
        this.relations = {
            'linuxes_mount': [ 'linux_mount_device', 'linux_mount_point', 'linux_mount_filesystem',
                               'linux_mount_options', 'linux_mount_dumpfreq', 'linux_mount_passnum' ],
        }
    };

    return Linux0;

})(Component);
