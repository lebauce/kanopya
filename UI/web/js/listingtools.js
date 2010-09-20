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

expandables = document.getElementsByClassName('expanddown');
for(i=0;i<expandables.length;i++) {
	expandables[i].onclick = expand;
}