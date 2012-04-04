(function() {
  var Jigsaw;

  Jigsaw = (function() {

    function Jigsaw() {
      var back_canvas, back_canvas_context, board, columns, pieces, pieces_canvas, player, refresh_rate, rows, starting_id, video_element;
      back_canvas = $('#back-canvas');
      pieces_canvas = $("#pieces-canvas");
      rows = 2;
      columns = 3;
      starting_id = 1;
      board = this.initBoard(rows, columns, starting_id);
      pieces = this.initPieces(rows, columns, back_canvas, starting_id);
      player = $('#player');
      video_element = $('#player')[0];
      video_element.muted = true;
      refresh_rate = 33;
      back_canvas_context = back_canvas[0].getContext('2d');
      this.renderVideoToBackCanvas(video_element, back_canvas_context, refresh_rate);
      this.renderBackCanvasToPieces(back_canvas, pieces, refresh_rate);
    }

    Jigsaw.prototype.initPieces = function(rows, columns, back_canvas, starting_id) {
      var back_canvas_left, back_canvas_top, cur_column, cur_left, cur_row, cur_top, i, next_id, num_pieces_needed, piece, piece_height, piece_width, pieces, should_move_to_next_row;
      pieces = [];
      next_id = starting_id;
      piece_width = back_canvas.width() / columns;
      piece_height = back_canvas.height() / rows;
      back_canvas_top = back_canvas.position().top;
      back_canvas_left = back_canvas.position().left;
      cur_row = 0;
      cur_column = 0;
      num_pieces_needed = rows * columns;
      for (i = 1; 1 <= num_pieces_needed ? i <= num_pieces_needed : i >= num_pieces_needed; 1 <= num_pieces_needed ? i++ : i--) {
        cur_top = back_canvas_top + (piece_height * cur_row);
        cur_left = back_canvas_left + (piece_width * cur_column);
        piece = this.createPiece(next_id, piece_width, piece_height, cur_top, cur_left);
        next_id++;
        piece.appendTo('#pieces-canvas');
        pieces.push(piece);
        should_move_to_next_row = i % (columns + 1) === 0;
        if (should_move_to_next_row) {
          cur_row++;
          cur_column = 0;
        } else {
          cur_column++;
        }
      }
      return pieces;
    };

    Jigsaw.prototype.createPiece = function(id, width, height, top, left) {
      var piece;
      piece = $("<canvas></canvas>").clone();
      piece.attr({
        'id': id,
        'width': width,
        'height': height,
        'top': top,
        'left': left
      });
      return piece;
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

    Jigsaw.prototype.renderVideoToBackCanvas = function(video_element, back_canvas_context, refresh_rate) {
      var _this = this;
      return setInterval(function() {
        video_element.play();
        return back_canvas_context.drawImage(video_element, 0, 0);
      }, refresh_rate);
    };

    Jigsaw.prototype.renderBackCanvasToPieces = function(back_canvas, pieces, refresh_rate) {
      var _this = this;
      return setInterval(function() {
        debugger;
        var height, i, left, piece, piece_context, top, width, _ref, _results;
        _results = [];
        for (i = 0, _ref = pieces.length - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
          piece = pieces[i];
          piece_context = piece[0].getContext('2d');
          left = parseFloat(piece.attr("left"));
          top = parseFloat(piece.attr("top"));
          width = parseFloat(piece.attr("width"));
          height = parseFloat(piece.attr("height"));
          _results.push(piece_context.drawImage(back_canvas, top, left, width, height, top, left, width, height));
        }
        return _results;
      }, refresh_rate);
    };

    return Jigsaw;

  })();

  $(function() {
    return window.jigsaw = new Jigsaw();
  });

}).call(this);
