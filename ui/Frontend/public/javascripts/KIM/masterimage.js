
require('jquery/jquery.form.js');

var MasterImage = (function() {

    function MasterImage(id) {
        this.id     = id;

        this.conf   = {};
        $.ajax({
            url     : '/api/masterimage/' + id,
            success : function(data) {
                this.conf   = data;
            }
        });
    }

    MasterImage.openUpload  = function() {
        var dialog  = $('<div>');
        var form    = $('<form>', { enctype : 'multipart/form-data' }).appendTo(dialog);
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

    return MasterImage;

})();
