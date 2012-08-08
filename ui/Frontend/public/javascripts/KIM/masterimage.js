
require('jquery/jquery.form.js');
require('common/formatters.js');

var MasterImage = (function() {

    function MasterImage(id) {
        this.id     = id;

        this.conf   = {};
        $.ajax({
            url     : '/api/masterimage/' + id,
            success : (function(that) {
                return (function(data) {
                    that.conf   = data;
                });
            })(this)
        });
    }

    MasterImage.prototype.details   = function() {
        $.ajax({
            url     : '/api/masterimage/' + this.id + '/getProvidedComponents',
            type    : 'POST',
            success : (function(that) {
                return (function(data) {
                    $('<div>', { id : 'masterimage_dialog' }).dialog({
                        title       : that.conf.masterimage_name,
                        draggable   : false,
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
                        ]
                    });
                });
            })(this)
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
            title       : 'Upload a new master image',
            draggable   : false,
            resizable   : false,
            modal       : true,
            close       : function() { $(this).remove(); },
            buttons     : {
                'Ok'        : function() { $(form).submit(); },
                'Cancel'    : function() { $(this).dialog('close'); }
            }
        });
    };

    MasterImage.list        = function(cid) {
        create_grid({
            content_container_id    : cid,
            grid_id                 : 'masterimages_list',
            url                     : '/api/masterimage',
            colNames                : [ 'Id', 'Name', 'Description', 'OS', 'Size' ],
            colModel                : [
                { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
                { name : 'masterimage_name', index : 'masterimage_name' },
                { name : 'masterimage_desc', index : 'masterimage_desc' },
                { name : 'masterimage_os', index : 'masterimage_os' },
                { name : 'masterimage_size', index : 'masterimage_size', formatter : bytesToMegsFormatter }
            ],
            details                 : {
                onSelectRow : function(eid) {
                    var mImg    = new MasterImage(eid);
                    mImg.details();
                }
            }
        });
    };

    return MasterImage;

})();

function masterimagesMainView(cid) {
    MasterImage.list(cid);
    var addMasterImageButton    = $('<a>', { text : 'Upload a master image' }).appendTo('#' + cid);
    $(addMasterImageButton).button({ icons : { primary : 'ui-icon-arrowthickstop-1-n' } });
    $(addMasterImageButton).bind('click', MasterImage.openUpload);
}
