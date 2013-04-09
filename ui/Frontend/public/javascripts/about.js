function openAbout(contentAbout){
    jQuery.get(contentAbout, function(data) {
        jQuery(document.createElement('div'))
        .html(data)
        .dialog({
            title           : 'Kanopya 1.7.0 release version',
            buttons         : [{text:'OK',click: function(){$(this).dialog('close');}, id:'button-ok'}],
            close           : function(){$(this).remove();},
            draggable       : true,
            modal           : true,
            dialogClass     : "no-close",
            resizable       : false,
            width           : 'auto'
        });
    });
}
