require('KIM/component.js');

var Novacontroller = (function(_super) {
    Novacontroller.prototype = new _super();

    function Novacontroller(id) {
        _super.call(this, id);

        this.displayed = [ 'overcommitment_cpu_factor', 'overcommitment_memory_factor', 'mysql5_id', 'amqp_id', 'keystone_id', 'kanopya_openstack_sync_id' ];

        this.relations = { 'repositories': [ 'repository_name', 'container_access_id' ] };
    };

    return Novacontroller;

})(Component);
