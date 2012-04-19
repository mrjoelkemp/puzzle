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
      pieces = this.initPieces(rows, columns, back_canvas, starting_id, neighbors);
      snapping_threshold = 30;
      this.setDraggingEvents(pieces, snapping_threshold);
      this.randomize(pieces);
      refresh_rate = 33;
      back_canvas_element = back_canvas[0];
      back_canvas_context = back_canvas_element.getContext('2d');
      this.renderVideoToBackCanvas(video_element, back_canvas_context, refresh_rate);
      this.renderBackCanvasToPieces(back_canvas_element, pieces, refresh_rate);
    }

    Jigsaw.prototype.randomize = function(pieces) {
      var center_pos, circle_point, i, ind, indices, num_points, p, points, radius, _i, _results, _results2;
      center_pos = {
        "x": $(window).width() / 2,
        "y": $(window).height() / 2
      };
      num_points = _.size(pieces);
      radius = 350;
      points = this.generatePointsAboutCircle(num_points, center_pos, radius);
      indices = (function() {
        _results = [];
        for (var _i = 0; 0 <= num_points ? _i < num_points : _i > num_points; 0 <= num_points ? _i++ : _i--){ _results.push(_i); }
        return _results;
      }).apply(this);
      indices = _.shuffle(indices);
      _results2 = [];
      for (i = 0; 0 <= num_points ? i < num_points : i > num_points; 0 <= num_points ? i++ : i--) {
        p = pieces[i + 1];
        ind = indices[i];
        circle_point = points[ind];
        _results2.push(this.movePiece(p, circle_point.x, circle_point.y));
      }
      return _results2;
    };

    Jigsaw.prototype.generatePointsAboutCircle = function(num_points, center, radius) {
      var centered, coords, degree, degrees, step;
      step = 360 / num_points;
      degrees = [];
      degree = 0;
      while (degree <= 360) {
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
          drag: function(e, ui) {
            var dragging_pos, group_exists, group_id;
            group_id = piece.data("group");
            group_exists = group_id !== -1;
            if (group_exists) {
              debugger;
              dragging_pos = ui.position;
              _this.dragGroup(group_id, piece, pieces, dragging_pos);
              piece.data("old_top", ui.position.top);
              return piece.data("old_left", ui.position.left);
            }
          },
          stop: function(e, ui) {
            var have_neighbors_to_snap, neighbors_objects, snappable_neighbors, snappable_neighbors_ids;
            _this.updateDetailedPosition(piece);
            neighbors_objects = _this.getNeighborObjects(piece, pieces);
            _.each(neighbors_objects, function(n) {
              return _this.updateDetailedPosition(n);
            });
            snappable_neighbors_ids = _this.findSnappableNeighbors(piece, neighbors_objects, snapping_threshold);
            snappable_neighbors = _this.getNeighborObjectsFromIds(pieces, snappable_neighbors_ids);
            have_neighbors_to_snap = !_.isEmpty(snappable_neighbors);
            if (have_neighbors_to_snap) {
              return _this.snapToNeighbors(piece, snappable_neighbors);
            }
          }
        });
      });
    };

    Jigsaw.prototype.dragGroup = function(group_id, piece, pieces, dragging_pos) {
      var group_objects, left_offset, top_offset,
        _this = this;
      top_offset = piece.data("old_top") - dragging_pos.top;
      left_offset = piece.data("old_left") - dragging_pos.left;
      group_objects = _.filter(pieces, function(p) {
        return p.data("group") === group_id;
      });
      group_objects = _.reject(group_objects, function(p) {
        return p.data("id") === piece.data("id");
      });
      return _.each(group_objects, function(p) {
        return _this.movePieceByOffsets(p, left_offset, top_offset);
      });
    };

    Jigsaw.prototype.getNeighborObjectsFromIds = function(pieces, neighbors_ids) {
      var neighbors_pieces;
      neighbors_pieces = _.map(neighbors_ids, function(id) {
        return pieces[id];
      });
      return neighbors_pieces;
    };

    Jigsaw.prototype.snapToNeighbors = function(current_piece, snappable_neighbors) {
      var cp_id, neighbors_points, neighbors_relations, objects_relations, pieces,
        _this = this;
      pieces = _.union(current_piece, snappable_neighbors);
      cp_id = current_piece.data("id");
      _.each(pieces, function(p) {
        p.data("group", cp_id);
        return p.css("border", "1px solid red");
      });
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
      top = piece.css("top");
      left = piece.css("left");
      new_left = left + left_offset;
      new_top = top + top_offset;
      piece.css("left", new_left);
      return piece.css("top", new_top);
    };

    Jigsaw.prototype.movePieceByOffsets = function(piece, left_offset, top_offset, move_speed) {
      var cp_pos, cp_pos_left, cp_pos_top, new_left, new_top;
      cp_pos = piece.data("position");
      cp_pos_top = cp_pos.top_left.y;
      cp_pos_left = cp_pos.top_left.x;
      new_left = cp_pos_left + left_offset;
      new_top = cp_pos_top + top_offset;
      return this.movePiece(piece, new_left, new_top, move_speed);
    };

    Jigsaw.prototype.movePiece = function(piece, x, y, speed) {
      if (speed == null) speed = 1900;
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
      var i, neighbor_id, neighbor_object, neighbor_relation, neighbors_objects_ids, neighbors_relations, snappable, snaps, _ref;
      neighbors_relations = this.getNeighborRelations(current_piece, neighbors_objects);
      snappable = [];
      neighbors_objects_ids = _.map(neighbors_objects, function(n) {
        return n.data("id");
      });
      for (i = 0, _ref = neighbors_objects_ids.length - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        neighbor_id = neighbors_objects_ids[i];
        neighbor_object = neighbors_objects[i];
        neighbor_relation = neighbors_relations[i];
        snaps = this.canSnap(current_piece, neighbor_object, neighbor_relation, snapping_threshold);
        if (snaps) snappable.push(neighbor_id);
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

  $(function() {
    return window.jigsaw = new Jigsaw();
  });

}).call(this);
