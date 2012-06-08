
function _require() {

    var loadedScripts = {};

    return (function(fileName) {
        if (fileName in loadedScripts) { return; }
        $.ajax({
            url         : '/javascripts/' + fileName,
            type        : 'GET',
            dataType    : 'script',
            async       : false,
            success     : function() {
                loadedScripts[fileName] = true;
            }
        });
    });

}

var require = _require();