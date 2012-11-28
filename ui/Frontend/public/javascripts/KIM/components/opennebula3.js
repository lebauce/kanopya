require('KIM/component.js');

var Opennebula3 = (function(_super) {
    Opennebula3.prototype = new _super();

    function Opennebula3(id) {
        _super.call(this, id);

        this.displayed = [ 'host_monitoring_interval', 'vm_polling_interval', 'port', 'hypervisor',
                           'debug_level', 'overcommitment_cpu_factor', 'overcommitment_memory_factor'];

        this.relations = { 'opennebula3_repositories': [ 'repository_name', 'container_access_id' ] };
    };

    return Opennebula3;

})(Component);
