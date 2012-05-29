$(document).ready(function () {
    var main_layout = $('body').layout(
               { 
                   applyDefaultStyles: true,
                   defaults : { 
                       resizable : false,
                       slidable : false,
                   },
                   north : { closable : false },
                   west : { closable : false, resizable : true},
               }
    );
    

    // Needed to fix bad panels resizing when opening Messages pane (south) for the first time
    // Layout will take in account the message grid size fill with data 
    //main_layout.resizeAll();
});
