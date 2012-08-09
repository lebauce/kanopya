
var SystemImage = (function(_super) {

    SystemImage.prototype       = new _super();
    SystemImage.list            = _super.list;

    SystemImage.prototype.type            = 'systemimage';
    SystemImage.prototype.columnNames     = [ 'id', 'Name', 'Description', 'Active' ];
    SystemImage.prototype.columnValues    = [
        { name : 'pk',                  index : 'pk',   hidden : true,  key : true, sorttype : 'int'    },
        { name : 'systemimage_name',    index : 'systemimage_name'                                      },
        { name : 'systemimage_desc',    index : 'systemimage_desc'                                      },
        { name : 'active',              index : 'active',   formatter : booleantostateformatter         }
    ];

    function SystemImage(id) {
        _super.call(id);
    }

    SystemImage.prototype.download  = function() {
    };

    return SystemImage;

})(Model);

function systemimagesMainView(cid) {
    SystemImage.list(cid);
}
