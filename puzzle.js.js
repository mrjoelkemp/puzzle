((function(){var a;a=function(){function a(){var a,b,c,d,e,f,g,h,i,j,k,l;h=$("#player");l=$("#player")[0];l.muted=!0;a=$("#back-canvas");g=$("#pieces-canvas");j=2;e=3;k=1;d=this.initBoard(j,e,k);f=this.initPieces(j,e,a,k);i=33;c=a[0];b=c.getContext("2d");this.renderVideoToBackCanvas(l,b,i);this.renderBackCanvasToPieces(c,f,i)}a.prototype.initPieces=function(a,b,c,d){var e,f,g,h,i,j,k,l,m,n,o,p,q,r;o=[];j=d;f=c.width();e=c.height();n=f/b;m=e/a;h=0;g=0;k=a*b;for(i=1;1<=k?i<=k:i>=k;1<=k?i++:i--){q=g;r=h;l=this.createPiece(j,n,m,q,r);j++;l.appendTo("#pieces-canvas");o.push(l);g+=n;p=g>=f;if(p){h+=m;g=0}}return o};a.prototype.createPiece=function(a,b,c,d,e){var f;f=$("<canvas></canvas>").clone();f.attr({id:a,width:b,height:c,videox:d,videoy:e}).draggable({snap:!1});return f};a.prototype.initBoard=function(a,b,c){var d,e,f,g,h,i;d=[];g=c;for(e=0,h=a-1;0<=h?e<=h:e>=h;0<=h?e++:e--){d[e]=[];for(f=0,i=b-1;0<=i?f<=i:f>=i;0<=i?f++:f--){d[e].push(g);g++}}return d};a.prototype.renderVideoToBackCanvas=function(a,b,c,d){var e=this;return setInterval(function(){a.play();return b.drawImage(a,0,0)},c)};a.prototype.renderBackCanvasToPieces=function(a,b,c){var d=this;return setInterval(function(){var c,d,e,f,g,h,i,j,k;k=[];for(d=0,j=b.length-1;0<=j?d<=j:d>=j;0<=j?d++:d--){e=b[d];f=e[0].getContext("2d");g=parseFloat(e.attr("videox"));h=parseFloat(e.attr("videoy"));i=parseFloat(e.attr("width"));c=parseFloat(e.attr("height"));k.push(f.drawImage(a,g,h,i,c,0,0,i,c))}return k},c)};return a}();$(function(){return window.jigsaw=new a})})).call(this);