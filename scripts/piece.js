// Generated by CoffeeScript 1.3.1
(function(){this.Piece=function(){function a(){}a.createPiece=function(a,b,c,d,e,f){var g;g=$("<canvas></canvas>").clone();g.attr({width:b,height:c,videox:d,videoy:e}).css("cursor","pointer").data("id",a).data("neighbors",f).data("group",-1).appendTo("#pieces-canvas").addClass("piece");return g};a.movePieceByOffsets=function(a,b,c,d){var e,f,g,h;d==null&&(d=0);f=parseFloat(a.css("top"));e=parseFloat(a.css("left"));g=e+b;h=f+c;return this.movePiece(a,g,h,d)};a.movePiece=function(a,b,c,d){d==null&&(d=1900);return a.animate({left:b,top:c},d)};return a}()}).call(this);