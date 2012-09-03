
require('common/model.js');

var SystemImage = (function(_super) {

    SystemImage.prototype       = new _super();
    SystemImage.list            = _super.list;

    SystemImage.prototype.type              = 'systemimage';
    SystemImage.prototype.columnNames       = [ 'id', 'Name', 'Description', 'Active', 'Download' ];
    SystemImage.prototype.columnValues      = [
        { name : 'pk',                  index : 'pk',   hidden : true,  key : true, sorttype : 'int'    },
        { name : 'systemimage_name',    index : 'systemimage_name'                                      },
        { name : 'systemimage_desc',    index : 'systemimage_desc'                                      },
        { name : 'active',              index : 'active',   formatter : booleantostateformatter         },
        { name : 'download',            index : 'download', noaction : true }
    ];
    SystemImage.prototype.afterInsertRow    = function(grid, rowid) {
        var cell            = $(grid).find("td[aria-describedby='systemimage_list_download']");
        var downloadButton  = $('<a>', { text : 'Download' }).button({ icons : { primary : 'ui-icon-arrowthickstop-1-s' } });
        $(downloadButton).click(function() {
            var sysImg  = new SystemImage(rowid);
            sysImg.download();
        });
        $(cell).append(downloadButton);
    };

    function SystemImage(id) {
        _super.call(this, id);
    }

    SystemImage.prototype.download  = function() {
        window.open('/systemimage/download/' + this.id);
    };

    return SystemImage;

})(Model);

function systemimagesMainView(cid) {
    SystemImage.list(cid);
}
