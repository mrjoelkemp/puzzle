(function() {
  var Jigsaw;

  Jigsaw = (function() {

    function Jigsaw() {
      var back_canvas, back_canvas_context, back_canvas_element, board, columns, neighbors, pieces, pieces_canvas, player, refresh_rate, rows, snapping_threshold, starting_id, video_element;
      player = $('#player');
      video_element = $('#player')[0];
      video_element.muted = true;
      back_canvas = $('#back-canvas');
      pieces_canvas = $("#pieces-canvas");
      rows = 2;
      columns = 3;
      starting_id = 1;
      board = this.initBoard(rows, columns, starting_id);
      neighbors = this.initNeighbors(rows, columns, board);
      debugger;
      pieces = this.initPieces(rows, columns, back_canvas, starting_id, neighbors);
      snapping_threshold = 20;
      this.setDraggingEvents(pieces, snapping_threshold);
      refresh_rate = 33;
      back_canvas_element = back_canvas[0];
      back_canvas_context = back_canvas_element.getContext('2d');
      this.renderVideoToBackCanvas(video_element, back_canvas_context, refresh_rate);
      this.renderBackCanvasToPieces(back_canvas_element, pieces, refresh_rate);
    }

    Jigsaw.prototype.setDraggingEvents = function(pieces, snapping_threshold) {
      return _.each(pieces, function(piece) {
        return piece.draggable({
          snap: false,
          snapMode: "inner",
          stack: ".piece",
          snapTolerance: snapping_threshold,
          opacity: 0.75,
          start: function(e, ui) {
            piece.data("old_top", piece.position().top);
            return piece.data("old_left", piece.position().left);
          },
          drag: function(e, ui) {},
          stop: function(e, ui) {
            debugger;
            var neighbors_objects;
            this.updateDetailedPosition(piece);
            neighbors_objects = this.getNeighborObjects(piece, pieces);
            _.each(neighbors_objects, function(n) {
              return this.updateDetailsPosition(n);
            });
            return this.findSnappableNeighbors(piece, neighbors_objects, snapping_threshold);
          }
        });
      });
    };

    Jigsaw.prototype.getNeighborObjects = function(current_piece, pieces) {
      var neighbors_ids, neighbors_obj, neighbors_pieces;
      neighbors_obj = current_piece.data("neighbors");
      neighbors_ids = _.values(neighbors_obj);
      neighbors_pieces = _.each(neighbors_ids, function(id) {
        return pieces[id];
      });
      return neighbors_pieces;
    };

    Jigsaw.prototype.updateDetailedPosition = function(piece) {
      var p_bottom, p_height, p_left, p_right, p_top, p_width;
      p_width = piece.attr("width");
      p_height = piece.attr("height");
      p_top = piece.position().top;
      p_left = piece.position().left;
      p_right = p_left + p_width;
      p_bottom = p_top + p_height;
      piece.data({
        "top": p_top,
        "left": p_left,
        "right": p_right,
        "bottom": p_bottom
      });
    };

    Jigsaw.prototype.findSnappableNeighbors = function(current_piece, neighbors_objects, snapping_threshold) {};

    Jigsaw.prototype.canSnap = function() {
      return false;
    };

    Jigsaw.prototype.initNeighbors = function(rows, columns, board) {
      var bottom, bottom_bound, col, current_position_id, left, left_bound, neighbors, right, right_bound, row, top, top_bound, _ref, _ref2;
      neighbors = {};
      left_bound = 0;
      top_bound = 0;
      right_bound = columns - 1;
      bottom_bound = rows - 1;
      for (row = 0, _ref = rows - 1; 0 <= _ref ? row <= _ref : row >= _ref; 0 <= _ref ? row++ : row--) {
        left = void 0;
        right = void 0;
        top = void 0;
        bottom = void 0;
        for (col = 0, _ref2 = columns - 1; 0 <= _ref2 ? col <= _ref2 : col >= _ref2; 0 <= _ref2 ? col++ : col--) {
          left = col !== left_bound ? board[row][col - 1] : void 0;
          top = row !== top_bound ? board[row - 1][col] : void 0;
          right = col !== right_bound ? board[row][col + 1] : void 0;
          bottom = row !== bottom_bound ? board[row + 1][col] : void 0;
          current_position_id = board[row][col];
          neighbors[current_position_id] = {
            "left": left,
            "right": right,
            "top": top,
            "bottom": bottom
          };
        }
      }
      return neighbors;
    };

    Jigsaw.prototype.initPieces = function(rows, columns, back_canvas, starting_id, neighbors) {
      var back_height, back_width, cur_column_left, cur_row_top, i, neighbor_hash, next_id, num_pieces_needed, piece, piece_height, piece_width, pieces, should_move_to_next_row, videox, videoy;
      pieces = {};
      next_id = starting_id;
      back_width = back_canvas.width();
      back_height = back_canvas.height();
      piece_width = back_width / columns;
      piece_height = back_height / rows;
      cur_row_top = 0;
      cur_column_left = 0;
      num_pieces_needed = rows * columns;
      for (i = 1; 1 <= num_pieces_needed ? i <= num_pieces_needed : i >= num_pieces_needed; 1 <= num_pieces_needed ? i++ : i--) {
        videox = cur_column_left;
        videoy = cur_row_top;
        neighbor_hash = neighbors[next_id];
        piece = this.createPiece(next_id, piece_width, piece_height, videox, videoy, neighbor_hash);
        pieces[next_id] = piece;
        next_id++;
        cur_column_left += piece_width;
        should_move_to_next_row = cur_column_left >= back_width;
        if (should_move_to_next_row) {
          cur_row_top += piece_height;
          cur_column_left = 0;
        }
      }
      return pieces;
    };

    Jigsaw.prototype.createPiece = function(id, width, height, videox, videoy, neighbors) {
      var piece;
      piece = $("<canvas></canvas>").clone();
      piece.attr({
        'width': width,
        'height': height,
        'videox': videox,
        'videoy': videoy
      }).css("cursor", "pointer").data("id", id).data("neighbors", neighbors).data("group", -1).appendTo('#pieces-canvas').addClass("piece");
      return piece;
    };

    Jigsaw.prototype.movePiece = function(piece, x, y) {
      return piece.animate({
        'left': x,
        'top': y
      }, 1900);
    };

    Jigsaw.prototype.initBoard = function(rows, columns, starting_id) {
      var board, i, j, next_id, _ref, _ref2;
      board = [];
      next_id = starting_id;
      for (i = 0, _ref = rows - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        board[i] = [];
        for (j = 0, _ref2 = columns - 1; 0 <= _ref2 ? j <= _ref2 : j >= _ref2; 0 <= _ref2 ? j++ : j--) {
          board[i].push(next_id);
          next_id++;
        }
      }
      return board;
    };

    Jigsaw.prototype.renderVideoToBackCanvas = function(video_element, back_canvas_context, refresh_rate, pieces) {
      var _this = this;
      return setInterval(function() {
        video_element.play();
        return back_canvas_context.drawImage(video_element, 0, 0);
      }, refresh_rate);
    };

    Jigsaw.prototype.renderBackCanvasToPieces = function(back_canvas_element, pieces, refresh_rate) {
      var _this = this;
      return setInterval(function() {
        var pieces_objects;
        pieces_objects = _.values(pieces);
        return _.each(pieces_objects, function(piece) {
          var height, piece_context, videox, videoy, width;
          piece_context = piece[0].getContext('2d');
          videox = parseFloat(piece.attr("videox"));
          videoy = parseFloat(piece.attr("videoy"));
          width = parseFloat(piece.attr("width"));
          height = parseFloat(piece.attr("height"));
          return piece_context.drawImage(back_canvas_element, videox, videoy, width, height, 0, 0, width, height);
        });
      }, refresh_rate);
    };

    return Jigsaw;

  })();

  $(function() {
    return window.jigsaw = new Jigsaw();
  });

}).call(this);
