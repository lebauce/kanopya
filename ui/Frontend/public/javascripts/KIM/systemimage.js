
var SystemImage = (function() {

    function SystemImage(id) {
        this.id = id;
    }

    SystemImage.list    = function(cid) {
        create_grid({
            content_container_id    : cid,
            grid_id                 : 'systemimage_list',
            url                     : '/api/systemimage',
            colNames                : [ 'id', 'Name', 'Description', 'Active' ],
            colModel                : [
                { name : 'pk',                  index : 'pk',   hidden : true,  key : true, sorttype : 'int'    },
                { name : 'systemimage_name',    index : 'systemimage_name'                                      },
                { name : 'systemimage_desc',    index : 'systemimage_desc'                                      },
                { name : 'active',              index : 'active',   formatter : booleantostateformatter         }
            ]
        });
    };

    return SystemImage;

})();

function systemimagesMainView(cid) {
    SystemImage.list(cid);
}
