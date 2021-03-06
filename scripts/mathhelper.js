// Generated by CoffeeScript 1.3.1
(function() {

  this.MathHelper = (function() {

    function MathHelper() {}

    MathHelper.generatePointsAboutCircle = function(num_points, center, radius) {
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

    MathHelper.isWithinThreshold = function(cp1, cp2, np1, np2, snapping_threshold) {
      var dist1, dist2, is_within;
      dist1 = this.manhattanDistance(cp1.x, cp1.y, np1.x, np1.y);
      dist2 = this.manhattanDistance(cp2.x, cp2.y, np2.x, np2.y);
      is_within = dist1 <= snapping_threshold && dist2 <= snapping_threshold;
      return is_within;
    };

    MathHelper.euclideanDistance = function(x1, y1, x2, y2) {
      var xs, ys;
      xs = Math.pow(x2 - x1, 2);
      ys = Math.pow(y2 - y1, 2);
      return Math.sqrt(xs + ys);
    };

    MathHelper.manhattanDistance = function(x1, y1, x2, y2) {
      var xs, ys;
      xs = Math.abs(x2 - x1);
      ys = Math.abs(y2 - y1);
      return xs + ys;
    };

    return MathHelper;

  })();

}).call(this);
