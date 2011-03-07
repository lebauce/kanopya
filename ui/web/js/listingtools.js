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


refreshgraph();

expandables = document.getElementsByClassName('expanddown');
for(i=0;i<expandables.length;i++) {
	expandables[i].onclick = expand_this;
}