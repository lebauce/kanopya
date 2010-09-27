function expand() { 
	
	if(this.className == 'expanddown') { 
		this.className = 'expandup';
		document.getElementById('t'+this.id.substring(1)).className = ''; 
	}
	else { 
		this.className = 'expanddown';
		document.getElementById('t'+this.id.substring(1)).className = 'hidden'; 
	}
}

graphs = document.getElementsByClassName('graph');
for(i=0;i<graphs.length;i++) {
	g = graphs[i]
	setTimeout(g.src = g.src + new Date().getMilliseconds(), 5000);
}

expandables = document.getElementsByClassName('expanddown');
for(i=0;i<expandables.length;i++) {
	expandables[i].onclick = expand;
}