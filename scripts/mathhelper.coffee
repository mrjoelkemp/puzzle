class @MathHelper
	@generatePointsAboutCircle: (num_points, center, radius) ->
		# Purpose: 	Generate a series of points about a circle centered at the 
		#			passed center scaled about the passed radius.
		# Precond:	center is an {x, y} object of float coordinates.
		#			radius > 0
		# Returns:	A list of {x, y} objects 
			
			# Segment euclidean space into num_points segments	
			step = 360 / num_points 
			degrees = []
			degree = 0
			while degree < 360
				degrees.push(degree)
				degree += step
			
			# Get the x and y trigonometric coordinates for each degree value
			# We want points along a circle of the passed radius
			# Both x and y are in the range -1 to 1 using cos() and sin()
			coords = _.map(degrees, (d) ->
				x = Math.cos(d) * radius
				y = Math.sin(d) * radius
				return "x": x, "y": y
			)
			
			# Center the points
			centered = _.map(coords, (c) -> 
				c.x += center.x
				c.y += center.y
				return c
			)
			
			return centered

	@isWithinThreshold: (cp1, cp2, np1, np2, snapping_threshold) ->
	# Purpose: 	Determines if the Euclidean distance between passed associated points are within the snapping
	# Precond:	cp1 compares to n1, cp2 compares to n2
	#			points are objects with an x and y value
	# Returns:	True if the both distances between the sets of points are within the threshold
	
		dist1 = @manhattanDistance(cp1.x, cp1.y, np1.x, np1.y)
		dist2 = @manhattanDistance(cp2.x, cp2.y, np2.x, np2.y)
		
		is_within = dist1 <= snapping_threshold && dist2 <= snapping_threshold
		return is_within
		
	@euclideanDistance: (x1, y1, x2, y2) ->
	# Purpose: 	Computes the euclidean distance of the passed points
	# Returns: 	The floating point distance
		xs = Math.pow((x2 - x1), 2)
		ys = Math.pow((y2 - y1), 2)
		return Math.sqrt(xs + ys)
	
	@manhattanDistance: (x1, y1, x2, y2) ->
	# Purpose: 	Computes the manhattan distance of the passed points
	# Returns: 	The floating point distance
		xs = Math.abs(x2 - x1)
		ys = Math.abs(y2 - y1)
		return xs + ys
