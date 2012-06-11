
function _require() {

    var loadedScripts = {};

    return (function(fileName) {
        var script;
        if (fileName in loadedScripts) { return; }
        $.ajax({
            url         : '/javascripts/' + fileName,
            type        : 'GET',
            dataType    : 'script',
            async       : false,
            complete    : function(jqXHR, textStatus) {
                loadedScripts[fileName] = true;
                if (textStatus === "parsererror") {
                    eval(jqXHR.responseText);
                }
            }
        });
    });

}

var require = _require();
