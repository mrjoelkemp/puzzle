// Generated by CoffeeScript 1.3.1
(function(){this.Piece=function(){function a(){}a.prototype.createPiece=function(a,b,c,d,e,f){var g;g=$("<canvas></canvas>").clone();g.attr({width:b,height:c,videox:d,videoy:e}).css("cursor","pointer").data("id",a).data("neighbors",f).data("group",-1).appendTo("#pieces-canvas").addClass("piece");return g};return a}()}).call(this);