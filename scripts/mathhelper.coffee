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