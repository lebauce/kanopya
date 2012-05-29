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
                   south : {
                       togglerContent_closed : 'Messages',
                       togglerLength_closed : 100,
                       spacing_closed : 14,
                       togglerContent_open : 'Messages',
                       togglerLength_open : 100,
                       spacing_open : 14,
                       initClosed : true,},
               }
    );
    
    // call for the themeswitcher
    $('#switcher').themeswitcher();
    
});
