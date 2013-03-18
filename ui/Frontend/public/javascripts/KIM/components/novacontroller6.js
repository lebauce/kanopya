require('KIM/component.js');

var Novacontroller6 = (function(_super) {
    Novacontroller6.prototype = new _super();

    function Novacontroller6(id) {
        _super.call(this, id);

        this.displayed = [ 'overcommitment_cpu_factor', 'overcommitment_memory_factor', 'amqp_id' ];

        this.relations = { 'repositories': [ 'repository_name', 'container_access_id' ] };
    };

    return Novacontroller6;

})(Component);
