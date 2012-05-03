// Generated by CoffeeScript 1.3.1
(function() {

  this.Jigsaw = (function() {

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
      pieces = this.initPieces(rows, columns, back_canvas, starting_id, neighbors);
      snapping_threshold = 40;
      this.setDraggingEvents(pieces, snapping_threshold);
      this.randomize(pieces);
      refresh_rate = 33;
      back_canvas_element = back_canvas[0];
      back_canvas_context = back_canvas_element.getContext('2d');
      this.renderVideoToBackCanvas(video_element, back_canvas_context, refresh_rate);
      this.renderBackCanvasToPieces(back_canvas_element, pieces, refresh_rate);
    }

    Jigsaw.prototype.randomize = function(pieces) {
      var center_pos, circle_point, i, ind, indices, num_points, offset, p, points, radius, _i, _j, _results, _results1;
      offset = 100;
      center_pos = {
        "x": ($(window).width() / 2) - offset,
        "y": $(window).height() / 2
      };
      num_points = _.size(pieces);
      radius = 300;
      points = this.generatePointsAboutCircle(num_points, center_pos, radius);
      indices = (function() {
        _results = [];
        for (var _i = 0; 0 <= num_points ? _i < num_points : _i > num_points; 0 <= num_points ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this);
      indices = _.shuffle(indices);
      _results1 = [];
      for (i = _j = 0; 0 <= num_points ? _j < num_points : _j > num_points; i = 0 <= num_points ? ++_j : --_j) {
        p = pieces[i + 1];
        ind = indices[i];
        circle_point = points[ind];
        _results1.push(this.movePiece(p, circle_point.x, circle_point.y, 400));
      }
      return _results1;
    };

    Jigsaw.prototype.generatePointsAboutCircle = function(num_points, center, radius) {
      var centered, coords, degree, degrees, step;
      step = 360 / num_points;
      degrees = [];
      degree = 0;
      while (degree < 360) {
        degrees.push(degree);
        degree += step;
      }
      coords = _.map(degrees, function(d) {
        var x, y;
        x = Math.cos(d) * radius;
        y = Math.sin(d) * radius;
        return {
          "x": x,
          "y": y
        };
      });
      centered = _.map(coords, function(c) {
        c.x += center.x;
        c.y += center.y;
        return c;
      });
      return centered;
    };

    Jigsaw.prototype.setDraggingEvents = function(pieces, snapping_threshold) {
      var _this = this;
      return _.each(pieces, function(piece) {
        piece.draggable({
          helper: "original",
          snap: false,
          snapMode: "inner",
          stack: ".piece",
          snapTolerance: snapping_threshold
        });
        piece.bind("dragstart", function(e, ui) {
          return _this.onDragStart(e, ui, piece);
        });
        piece.bind("drag", function(e, ui) {
          return _this.onDrag(e, ui, piece, pieces);
        });
        return piece.bind("dragstop", function(e, ui) {
          return _this.onDragStop(piece, pieces, snapping_threshold);
        });
      });
    };

    Jigsaw.prototype.onDragStart = function(e, ui, piece) {
      return this.updateOldPosition(piece, ui.offset);
    };

    Jigsaw.prototype.onDrag = function(e, ui, piece, pieces) {
      var dragging_pos, group_exists, group_id;
      dragging_pos = {
        "left": parseFloat(ui.offset.left),
        "top": parseFloat(ui.offset.top)
      };
      group_id = piece.data("group");
      group_exists = group_id !== -1;
      if (group_exists) {
        this.dragGroup(group_id, piece, pieces, dragging_pos);
      }
      return this.updateOldPosition(piece, ui.offset);
    };

    Jigsaw.prototype.updateOldPosition = function(piece, ui_offset) {
      piece.data("old_top", parseFloat(ui_offset.top));
      return piece.data("old_left", parseFloat(ui_offset.left));
    };

    Jigsaw.prototype.getGroupObjects = function(group_id, piece, pieces) {
      var group_objects;
      group_objects = _.filter(pieces, function(p) {
        return p.data("group") === group_id;
      });
      group_objects = _.reject(group_objects, function(p) {
        return p.data("id") === piece.data("id");
      });
      return group_objects;
    };

    Jigsaw.prototype.dragGroup = function(group_id, piece, pieces, offset_obj) {
      var drag_left_delta, drag_top_delta, group_objects,
        _this = this;
      group_objects = this.getGroupObjects(group_id, piece, pieces);
      drag_top_delta = offset_obj.top - piece.data("old_top");
      drag_left_delta = offset_obj.left - piece.data("old_left");
      return _.each(group_objects, function(p) {
        var new_left, new_top, pleft, ptop;
        ptop = parseFloat(p.css("top"));
        pleft = parseFloat(p.css("left"));
        new_top = ptop + drag_top_delta;
        new_left = pleft + drag_left_delta;
        return p.css({
          "top": new_top,
          "left": new_left
        });
      });
    };

    Jigsaw.prototype.movePieceByOffsets = function(piece, left_offset, top_offset, move_speed) {
      var cp_pos_left, cp_pos_top, new_left, new_top;
      if (move_speed == null) {
        move_speed = 0;
      }
      cp_pos_top = parseFloat(piece.css('top'));
      cp_pos_left = parseFloat(piece.css('left'));
      new_left = cp_pos_left + left_offset;
      new_top = cp_pos_top + top_offset;
      return this.movePiece(piece, new_left, new_top, move_speed);
    };

    Jigsaw.prototype.onDragStop = function(piece, pieces, snapping_threshold) {
      var have_neighbors_to_snap, neighbors_objects, snappable_neighbors, snappable_neighbors_ids,
        _this = this;
      this.updateDetailedPosition(piece);
      neighbors_objects = this.getNeighborObjects(piece, pieces);
      _.each(neighbors_objects, function(n) {
        return _this.updateDetailedPosition(n);
      });
      snappable_neighbors_ids = this.findSnappableNeighbors(piece, neighbors_objects, snapping_threshold);
      snappable_neighbors = this.getNeighborObjectsFromIds(pieces, snappable_neighbors_ids);
      have_neighbors_to_snap = !_.isEmpty(snappable_neighbors);
      if (have_neighbors_to_snap) {
        this.propagateSnap(piece, snappable_neighbors, pieces);
        this.snapToNeighbors(piece, snappable_neighbors);
        return this.checkWinCondition(pieces);
      }
    };

    Jigsaw.prototype.checkWinCondition = function(pieces) {
      var g_id, game_won, group_members, num_pieces;
      num_pieces = _.size(pieces);
      g_id = pieces[1].data("group");
      group_members = _.filter(pieces, function(p) {
        return p.data("group") === g_id;
      });
      game_won = num_pieces === _.size(group_members);
      if (game_won) {
        return this.updateGameStatus("You Win!");
      }
    };

    Jigsaw.prototype.updateGameStatus = function(msg) {
      return $('#game-status').html("<span>" + msg + "</span>").addClass("win");
    };

    Jigsaw.prototype.propagateSnap = function(piece, snappable_neighbors, pieces) {
      var p_gid,
        _this = this;
      p_gid = piece.data("id");
      piece.data("group", p_gid);
      _.each(snappable_neighbors, function(n) {
        var has_group, n_gid, n_group_members;
        n_gid = n.data("group");
        has_group = n_gid !== -1;
        if (has_group) {
          n_group_members = _this.getGroupObjects(n_gid, n, pieces);
          return _.each(n_group_members, function(ngm) {
            return ngm.data("group", p_gid);
          });
        }
      });
      return _.each(snappable_neighbors, function(sn) {
        return sn.data("group", p_gid);
      });
    };

    Jigsaw.prototype.getNeighborObjectsFromIds = function(pieces, neighbors_ids) {
      var neighbors_pieces;
      neighbors_pieces = _.map(neighbors_ids, function(id) {
        return pieces[id];
      });
      return neighbors_pieces;
    };

    Jigsaw.prototype.debug_colorObjectsFromId = function(pieces) {
      var colors;
      colors = ["red", "green", "blue", "yellow", "black", "pink"];
      return _.each(pieces, function(p) {
        var p_gid;
        p_gid = p.data("group");
        return p.css("border", "3px solid " + colors[p_gid]);
      });
    };

    Jigsaw.prototype.snapToNeighbors = function(current_piece, snappable_neighbors) {
      var neighbors_points, neighbors_relations, objects_relations,
        _this = this;
      neighbors_relations = this.getNeighborRelations(current_piece, snappable_neighbors);
      objects_relations = _.zip(snappable_neighbors, neighbors_relations);
      neighbors_points = _.map(objects_relations, function(arr) {
        var neighbor, relation;
        neighbor = arr[0];
        relation = arr[1];
        return _this.getSnappablePoints(current_piece, neighbor, relation);
      });
      return _.each(neighbors_points, function(points) {
        var left_offset, offsets, top_offset;
        offsets = _this.getMovementOffset(points[0], points[1], points[2], points[3]);
        left_offset = offsets.left_offset;
        top_offset = offsets.top_offset;
        return _this.movePieceByOffsets(current_piece, left_offset, top_offset, 0);
      });
    };

    Jigsaw.prototype.setPositionByOffsets = function(piece, left_offset, top_offset) {
      var left, new_left, new_top, top;
      top = parseFloat(piece.css("top"));
      left = parseFloat(piece.css("left"));
      new_left = left + left_offset;
      new_top = top + top_offset;
      piece.css("left", new_left);
      return piece.css("top", new_top);
    };

    Jigsaw.prototype.movePiece = function(piece, x, y, speed) {
      if (speed == null) {
        speed = 1900;
      }
      return piece.animate({
        'left': x,
        'top': y
      }, speed);
    };

    Jigsaw.prototype.getMovementOffset = function(cp1, cp2, np1, np2) {
      var nleft_to_pleft, ntop_to_ptop;
      ntop_to_ptop = np1.y - cp1.y;
      nleft_to_pleft = np2.x - cp2.x;
      return {
        "top_offset": ntop_to_ptop,
        "left_offset": nleft_to_pleft
      };
    };

    Jigsaw.prototype.getNeighborRelations = function(current_piece, neighbors_objects) {
      var cp_neighbors_object, neighbors_objects_ids, neighbors_relations,
        _this = this;
      cp_neighbors_object = current_piece.data("neighbors");
      neighbors_objects_ids = _.map(neighbors_objects, function(n) {
        return n.data("id");
      });
      neighbors_objects_ids = _.compact(neighbors_objects_ids);
      neighbors_relations = _.map(neighbors_objects_ids, function(nid) {
        return _this.getKeyFromValue(cp_neighbors_object, nid);
      });
      return neighbors_relations;
    };

    Jigsaw.prototype.getNeighborObjects = function(current_piece, pieces) {
      var neighbors_ids, neighbors_obj, neighbors_pieces;
      neighbors_obj = current_piece.data("neighbors");
      neighbors_ids = _.values(neighbors_obj);
      neighbors_ids = _.compact(neighbors_ids);
      neighbors_pieces = this.getNeighborObjectsFromIds(pieces, neighbors_ids);
      return neighbors_pieces;
    };

    Jigsaw.prototype.updateDetailedPosition = function(piece) {
      var bottom, bottom_left, bottom_right, height, left, right, top, top_left, top_right, width;
      width = parseFloat(piece.attr("width"));
      height = parseFloat(piece.attr("height"));
      top = parseFloat(piece.position().top);
      left = parseFloat(piece.position().left);
      right = left + width;
      bottom = top + height;
      top_left = {
        "x": left,
        "y": top
      };
      top_right = {
        "x": right,
        "y": top
      };
      bottom_left = {
        "x": left,
        "y": bottom
      };
      bottom_right = {
        "x": right,
        "y": bottom
      };
      piece.data("position", {
        "top_left": top_left,
        "top_right": top_right,
        "bottom_left": bottom_left,
        "bottom_right": bottom_right
      });
    };

    Jigsaw.prototype.findSnappableNeighbors = function(current_piece, neighbors_objects, snapping_threshold) {
      var i, neighbor_id, neighbor_object, neighbor_relation, neighbors_objects_ids, neighbors_relations, snappable, snaps, _i, _ref;
      neighbors_relations = this.getNeighborRelations(current_piece, neighbors_objects);
      snappable = [];
      neighbors_objects_ids = _.map(neighbors_objects, function(n) {
        return n.data("id");
      });
      for (i = _i = 0, _ref = neighbors_objects_ids.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        neighbor_id = neighbors_objects_ids[i];
        neighbor_object = neighbors_objects[i];
        neighbor_relation = neighbors_relations[i];
        snaps = this.canSnap(current_piece, neighbor_object, neighbor_relation, snapping_threshold);
        if (snaps) {
          snappable.push(neighbor_id);
        }
      }
      return snappable;
    };

    Jigsaw.prototype.getKeyFromValue = function(obj, value) {
      var desired_key, keys;
      keys = _.keys(obj);
      desired_key = _.find(keys, function(k) {
        return obj[k] === value;
      });
      return desired_key;
    };

    Jigsaw.prototype.canSnap = function(current_piece, neighbor_object, neighbor_relation, snapping_threshold) {
      var points, snappable;
      points = this.getSnappablePoints(current_piece, neighbor_object, neighbor_relation);
      snappable = this.isWithinThreshold(points[0], points[1], points[2], points[3], snapping_threshold);
      return snappable;
    };

    Jigsaw.prototype.getSnappablePoints = function(current_piece, neighbor_piece, neighbor_relation) {
      var cp, np, points;
      cp = current_piece.data("position");
      np = neighbor_piece.data("position");
      points = [];
      switch (neighbor_relation) {
        case "right":
          points = [cp.top_right, cp.bottom_right, np.top_left, np.bottom_left];
          break;
        case "left":
          points = [cp.top_left, cp.bottom_left, np.top_right, np.bottom_right];
          break;
        case "top":
          points = [cp.top_left, cp.top_right, np.bottom_left, np.bottom_right];
          break;
        case "bottom":
          points = [cp.bottom_left, cp.bottom_right, np.top_left, np.top_right];
      }
      return points;
    };

    Jigsaw.prototype.isWithinThreshold = function(cp1, cp2, np1, np2, snapping_threshold) {
      var dist1, dist2, is_within;
      dist1 = this.manhattanDistance(cp1.x, cp1.y, np1.x, np1.y);
      dist2 = this.manhattanDistance(cp2.x, cp2.y, np2.x, np2.y);
      is_within = dist1 <= snapping_threshold && dist2 <= snapping_threshold;
      return is_within;
    };

    Jigsaw.prototype.euclideanDistance = function(x1, y1, x2, y2) {
      var xs, ys;
      xs = Math.pow(x2 - x1, 2);
      ys = Math.pow(y2 - y1, 2);
      return Math.sqrt(xs + ys);
    };

    Jigsaw.prototype.manhattanDistance = function(x1, y1, x2, y2) {
      var xs, ys;
      xs = Math.abs(x2 - x1);
      ys = Math.abs(y2 - y1);
      return xs + ys;
    };

    Jigsaw.prototype.initNeighbors = function(rows, columns, board) {
      var bottom, bottom_bound, col, current_position_id, left, left_bound, neighbors, right, right_bound, row, top, top_bound, _i, _j, _ref, _ref1;
      neighbors = {};
      left_bound = 0;
      top_bound = 0;
      right_bound = columns - 1;
      bottom_bound = rows - 1;
      for (row = _i = 0, _ref = rows - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; row = 0 <= _ref ? ++_i : --_i) {
        left = void 0;
        right = void 0;
        top = void 0;
        bottom = void 0;
        for (col = _j = 0, _ref1 = columns - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; col = 0 <= _ref1 ? ++_j : --_j) {
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
      var back_height, back_width, cur_column_left, cur_row_top, i, neighbor_hash, next_id, num_pieces_needed, piece, piece_height, piece_width, pieces, should_move_to_next_row, videox, videoy, _i;
      pieces = {};
      next_id = starting_id;
      back_width = back_canvas.width();
      back_height = back_canvas.height();
      piece_width = back_width / columns;
      piece_height = back_height / rows;
      cur_row_top = 0;
      cur_column_left = 0;
      num_pieces_needed = rows * columns;
      for (i = _i = 1; 1 <= num_pieces_needed ? _i <= num_pieces_needed : _i >= num_pieces_needed; i = 1 <= num_pieces_needed ? ++_i : --_i) {
        videox = cur_column_left;
        videoy = cur_row_top;
        neighbor_hash = neighbors[next_id];
        piece = Piece.createPiece(next_id, piece_width, piece_height, videox, videoy, neighbor_hash);
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

    Jigsaw.prototype.initBoard = function(rows, columns, starting_id) {
      var board, i, j, next_id, _i, _j, _ref, _ref1;
      board = [];
      next_id = starting_id;
      for (i = _i = 0, _ref = rows - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        board[i] = [];
        for (j = _j = 0, _ref1 = columns - 1; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
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
      var pieces_objects,
        _this = this;
      pieces_objects = _.values(pieces);
      return setInterval(function() {
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

  /* -------------------------------------------- 
       Begin piece.coffee 
  --------------------------------------------
  */


  this.Piece = (function() {

    function Piece() {}

    Piece.createPiece = function(id, width, height, videox, videoy, neighbors) {
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

    return Piece;

  })();

  /* -------------------------------------------- 
       Begin piecemanager.coffee 
  --------------------------------------------
  */


  this.PieceManager = (function() {

    function PieceManager(board_dimensions, piece_dimensions, neighbors) {}

    PieceManager.prototype.initPieces = function(board_dimensions, piece_dimensions, neighbors) {
      var cols, piece_height, piece_width, rows, starting_id;
      starting_id = 1;
      piece_width = piece_dimensions.width;
      piece_height = piece_dimensions.height;
      rows = board_dimensions.rows;
      return cols = board_dimensions.columns;
    };

    return PieceManager;

  })();

}).call(this);
