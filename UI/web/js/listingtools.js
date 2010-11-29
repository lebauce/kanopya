function expand( elem ) {
	if(elem.className == 'expanddown') { 
		elem.className = 'expandup';
		document.getElementById('t'+elem.id.substring(1)).className = ''; 
	}
	else { 
		elem.className = 'expanddown';
		document.getElementById('t'+elem.id.substring(1)).className = 'hidden'; 
	}
}

function expand_this () {
	expand(this);
}

function refreshgraph() {
	graphs = document.getElementsByClassName('graph');
	for(i=0;i<graphs.length;i++) {
		g = graphs[i];
		if (g.style.display == 'block') {
			g.src = g.src.split('?')[0] + '?' + new Date().getMilliseconds() ;
		} 
	}
	setTimeout('refreshgraph()', 5000);
}

function display_graph(graph_class) {
	graphs = document.getElementsByClassName('multi_graph');
	for(i=0;i<graphs.length;i++) {
		g = graphs[i];		
		g.style.display = 'none';
	}
	graphs = document.getElementsByClassName(graph_class);
	for(i=0;i<graphs.length;i++) {
		g = graphs[i];		
		g.style.display = 'block';
	}
}

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

refreshgraph();

expandables = document.getElementsByClassName('expanddown');
for(i=0;i<expandables.length;i++) {
	expandables[i].onclick = expand_this;
}