// Generated by CoffeeScript 1.3.1
(function(){this.Piece=function(){function a(){}a.createPiece=function(a,b,c,d,e,f){var g;g=$("<canvas></canvas>").clone();g.attr({width:b,height:c,videox:d,videoy:e}).css("cursor","pointer").data("id",a).data("neighbors",f).data("group",-1).appendTo("#pieces-canvas").addClass("piece");return g};a.updateDetailedPosition=function(a){var b,c,d,e,f,g,h,i,j,k;k=parseFloat(a.attr("width"));e=parseFloat(a.attr("height"));h=parseFloat(a.position().top);f=parseFloat(a.position().left);g=f+k;b=h+e;i={x:f,y:h};j={x:g,y:h};c={x:f,y:b};d={x:g,y:b};return a.data("position",{top_left:i,top_right:j,bottom_left:c,bottom_right:d})};a.updateOldPosition=function(a,b){a.data("old_top",parseFloat(b.top));return a.data("old_left",parseFloat(b.left))};a.setPositionByOffsets=function(a,b,c){var d,e,f,g;g=parseFloat(a.css("top"));d=parseFloat(a.css("left"));e=d+b;f=g+c;a.css("left",e);return a.css("top",f)};a.getMovementOffset=function(a,b,c,d){var e,f;f=c.y-a.y;e=d.x-b.x;return{top_offset:f,left_offset:e}};a.getGroupObjects=function(a,b,c){var d;d=_.filter(c,function(b){return b.data("group")===a});d=_.reject(d,function(a){return a.data("id")===b.data("id")});return d};a.movePieceByOffsets=function(a,b,c,d){var e,f,g,h;d==null&&(d=0);f=parseFloat(a.css("top"));e=parseFloat(a.css("left"));g=e+b;h=f+c;return this.movePiece(a,g,h,d)};a.movePiece=function(a,b,c,d){d==null&&(d=1900);return a.animate({left:b,top:c},d)};return a}()}).call(this);