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
	document.getElementById( "conso_graph" ).src = "/graph/monitor/graph/" + graph_name;
}


$(document).ready(function(){

	$("#default_timeline").click();
	refresh_status();


	$("#conso_graph").error( function () { $("#img_div").hide(); $("#load_error_div").show(); } );
	$("#conso_graph").load( function () { $("#img_div").show(); $("#load_error_div").hide(); } );
	
});