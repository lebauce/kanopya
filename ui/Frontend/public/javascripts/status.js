function refresh_status() {
    var xhr = new XMLHttpRequest();
    //if (document.getElementById("admin_status") == null) return;
    xhr.open("GET", "/cgi/kanopya.cgi/systemstatus/xml_admin_status");
    xhr.overrideMimeType('text/xml');
    xhr.onreadystatechange = function() {
      if (xhr.readyState == 4 && xhr.status == 200) {
            elems = xhr.responseXML.documentElement.getElementsByTagName('elem');
            for (index=0;index<elems.length;index++) {
                  var currentNode = elems[index];
                 document.getElementById( currentNode.getAttribute('id') ).className = currentNode.getAttribute('class');
            }
        }
      }
    xhr.send(null);
    setTimeout('refresh_status()', 5000);
}

function change_timeline( period ) {
    var graph_name = "graph_consumption_" + period + ".png";
    document.getElementById( "conso_graph" ).src = "/images/graphs/" + graph_name;
}


$(document).ready(function(){
    $("#default_timeline").click();

    function show_log (log_link) {
        $.ajax({
            url: "/dashboard/logs",
            type: "POST",
            data: "log_id=" + log_link.attr('id'),
            dataType: "text",
            success: function(msg){
                $("#log_container").html(msg);
            },
            error: function(error, text, thor) {
                $("#log_container").html("An error.");
            }
        });
    }

    $("#conso_graph").error( function () { $("#img_div").hide(); $("#load_error_div").show(); } );
    $("#conso_graph").load( function () { $("#img_div").show(); $("#load_error_div").hide(); } );
    

    $(".log_link").click( function () {
        $('.selected_link').removeClass('selected_link');
        $(this).addClass('selected_link');
        show_log($(this));
    } ).addClass('clickable');
});
