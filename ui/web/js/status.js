function refresh_status() {
	var xhr = new XMLHttpRequest();
	//if (document.getElementById("admin_status") == null) return;
	xhr.open("GET", "http://127.0.0.1/cgi/mcsui.cgi/systemstatus/xml_admin_status");
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

refresh_status();