
require('common/model.js');

var Kernel  = (function(_super) {

    Kernel.prototype    = new _super();
    Kernel.list         = _super.list;

    Kernel.prototype.type           = 'kernel';
    Kernel.prototype.columnNames    = [ 'id', 'Name', 'Version', 'Description' ];
    Kernel.prototype.columnValues   = [
        { name : 'pk',              index : 'pk', hidden : true, key : true, sorttype : 'int' },
        { name : 'kernel_name',     index : 'kernel_name' },
        { name : 'kernel_version',  index : 'kernel_version' },
        { name : 'kernel_desc',     index : 'kernel_desc' }
    ];

    function Kernel(id) {
        _super.call(this, id);
    }

    return Kernel;

})(Model);
