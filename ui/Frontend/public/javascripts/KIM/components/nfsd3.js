require('KIM/component.js');

var Nfsd3 = (function(_super) {
    Nfsd3.prototype = new _super();

    function Nfsd3(id) {
        _super.call(this, id);

        this.displayed = [];
        this.relations = {
            'container_accesses': [ 'container_id', 'container_access_export', 'nfs_container_access_client_name', 'nfs_container_access_client_options' ]
        };
    };

    return Nfsd3;

})(Component);
