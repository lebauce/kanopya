function openAbout () {
    $.ajax({
        url      : '/about',
        dataType : 'html',
        success  : function(html) {
            jQuery(document.createElement('div'))
            .html(html)
            .dialog({
                title       : 'About HCM',
                buttons     : [ { text : 'OK', click : function(){ $(this).dialog('close'); }, id : 'button-ok'} ],
                close       : function(){
                    $(this).remove();
                },
                draggable   : true,
                modal       : true,
                dialogClass : "no-close",
                resizable   : false,
                width       : 'auto'
            });
        },
    });
}
