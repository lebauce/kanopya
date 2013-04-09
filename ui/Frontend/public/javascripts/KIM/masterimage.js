
require('jquery/jquery.form.js');
require('common/formatters.js');

require('common/model.js');

var MasterImage = (function(_super) {
    MasterImage.prototype   = new _super();
    MasterImage.list        = _super.list;

    MasterImage.prototype.type          = 'masterimage';
    MasterImage.prototype.columnNames   = [ 'Id', 'Name', 'Description', 'OS', 'Size' ];
    MasterImage.prototype.columnValues  = [
        { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
        { name : 'masterimage_name', index : 'masterimage_name' },
        { name : 'masterimage_desc', index : 'masterimage_desc' },
        { name : 'masterimage_os', index : 'masterimage_os' },
        { name : 'masterimage_size', index : 'masterimage_size', formatter : bytesToMegsFormatter }
    ];
    MasterImage.prototype.details       = {
        onSelectRow : function(eid) {
            var mImg    = new MasterImage(eid);
            mImg.detailsFunc();
        }
    };

    function MasterImage(id) {
        _super.call(this, id);
    }

    MasterImage.prototype.detailsFunc   = function() {
        var _this = this;
        $.ajax({
            url     : '/api/masterimage/' + this.id  + '/component_types',
            type    : 'GET',
            success : function(data) {
                $('<div>', { id : 'masterimage_dialog' }).dialog({
                    title       : _this.conf.masterimage_name,
                    resizable   : false,
                    modal       : true,
                    width       : 450,
                    close       : function() { $(this).remove(); }
                });
                create_grid({
                    content_container_id    : 'masterimage_dialog',
                    grid_id                 : 'provided_components_list',
                    data                    : data,
                    colNames                : [ 'Category', 'Name', 'Version' ],
                    colModel                : [
                        { name : 'component_category', index : 'component_category' },
                        { name : 'component_name', index : 'component_name' },
                        { name : 'component_version', index : 'component_version', width : '50' }
                    ],
                    action_delete           : 'no'
                });
            }
        });
    };

    MasterImage.openUpload  = function() {
        var dialog  = $('<div>');
        var form    = $('<form>', { enctype : 'multipart/form-data' }).appendTo(dialog);
        $(dialog).append('<br />');
        var load    = $('<div>').progressbar({ value : 0 }).appendTo(dialog); 
        $(form).append($('<input>', { type : 'file', name : 'file',  }));
        $(form).submit(function(event) {
            $(this).ajaxSubmit({
                url             : '/uploadmasterimage',
                type            : 'POST',
                success         : function() {
                    $(dialog).dialog('close');
                },
                uploadProgress  : function(e, position, total, percent) {
                    $(load).progressbar('value', percent);
                },
            });
            return false;
        });
        $(dialog).dialog({
            title       : 'Upload a master image',
            resizable   : false,
            modal       : true,
            dialogClass : "no-close",
            buttons     : [
                {id:'button-cancel',text:'Cancel',click: function() { $(this).dialog('close'); }},
                {id:'button-ok',text:'Ok',click: function() { $(form).submit(); }}  
            ]
        });
    };

    return MasterImage;

})(Model);

function masterimagesMainView(cid) {
    MasterImage.list(cid);
    var action_div=$('#' + cid).prevAll('.action_buttons'); 
    var addMasterImageButton    = $('<a>', { text : 'Upload a master image' }).appendTo(action_div);
    $(addMasterImageButton).button({ icons : { primary : 'ui-icon-arrowthickstop-1-n' } });
    $(addMasterImageButton).bind('click', MasterImage.openUpload);
}
