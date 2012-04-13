class Jigsaw
	# TODO: Accept strings of div IDs for video player, back canvas, and pieces canvas. This way, the id changes are limited to one location.
	constructor: ->
		# Prep the back canvas and video
		player = $('#player')
		video_element = $('#player')[0]
		# DEBUG: Remove this
		video_element.muted = true
		
		# Back canvas renders the video
		back_canvas = $('#back-canvas')
		
		# Pieces canvas consists of smaller canvases that are each rendering parts of the back_canvas	
		pieces_canvas = $("#pieces-canvas")
		
		# Dimensions of the board
		rows = 2
		columns = 3
		
		# Pieces and the board are linked by IDs
		# We can pass this to those functions to ensure a common starting id
		starting_id = 1		
		
		# Initialize a 2D board to retain neighbor information for snapping
		board = @initBoard(rows, columns, starting_id)
		
		# Generate a lookup table for finding a piece's list of neighbors
		neighbors = @initNeighbors(rows, columns, board)
		#debugger
		# We pass the board to tell pieces who they snap to
		pieces = @initPieces(rows, columns, back_canvas, starting_id, neighbors)
		
		# Pixel distance for snapping between neighbors
		snapping_threshold = 30
		# Set up the draggable actions and events for each piece
		@setDraggingEvents(pieces, snapping_threshold)
	
		# The refresh delay between setInterval() calls
		refresh_rate = 33
		back_canvas_element = back_canvas[0]
		back_canvas_context = back_canvas_element.getContext('2d')	
		@renderVideoToBackCanvas(video_element, back_canvas_context, refresh_rate)
		@renderBackCanvasToPieces(back_canvas_element, pieces, refresh_rate)
	
	setDraggingEvents: (pieces, snapping_threshold) ->
	# Purpose: 	Initializes the dragging events for each piece in the passed list
		_.each(pieces, (piece) =>	# Avoid the piece's context
			piece.draggable({
				snap	: false,
				snapMode: "inner",
				stack	: ".piece",					# Dragged piece has a higher z-index
				snapTolerance: snapping_threshold,	# Pixel distance to initiate snapping
				opacity: 0.75,						# Make the dragged piece lighter for now. TODO: Remove when we have collision detection.
				start	: (e, ui) ->
					# Remember where you are so the movement distance can be computed
					piece.data("old_top", piece.position().top)
					piece.data("old_left", piece.position().left)
				drag	: (e, ui) ->
					# Drag every (snapped) piece in the group
					# dragGroup(group_id)
				stop	: (e, ui) =>	# Avoid the piece's context
					
					# Update detailed positional information for current piece
					@updateDetailedPosition(piece)
					
					# Grab neighboring pieces
					# Note: we know that we're connected to at most 3 other pieces, so it's not expensive to 
					#	fetch the neighbors on every mouseup
					neighbors_objects = @getNeighborObjects(piece, pieces)
										
					# Update detailed positional info of neighboring pieces 
					# FIXME: Should this always be a just-in-case, or do the neighbors update their own positions?
					_.each(neighbors_objects, (n) => @updateDetailedPosition(n))
					debugger
					# Find and extract snappable neighbor(s)
					@findSnappableNeighbors(piece, neighbors_objects, snapping_threshold)
					
					# Trigger snapping of the current piece to the snappable neighbor(s)
					#snapToCloseNeighbors(piece, neighbors)
										
					# Check for a win condition: all pieces are snapped together
					
			})	#end draggable()
		)
		
	getNeighborObjects: (current_piece, pieces) ->
	# Purpose:	Extracts the neighboring piece objects for the passed current piece
	# Returns: 	A list of neighbor piece objects.
		neighbors_obj = current_piece.data("neighbors")
		neighbors_ids = _.values(neighbors_obj)
		
		# Remove the undefined ids for boundary pieces
		neighbors_ids = _.reject(neighbors_ids, (id) -> return !id?)
		
		# Grab pieces associated with neighbor ids
		neighbors_pieces = _.map(neighbors_ids, (id) -> return pieces[id])
		
		return neighbors_pieces
		
	updateDetailedPosition: (piece) ->
	# Purpose: 	Updates the hidden positional (top, left, bottom, right) data of the passed piece
	# TODO: Move this to the piece class
		width 	= parseFloat(piece.attr("width"))
		height	= parseFloat(piece.attr("height"))
		
		top 	= parseFloat(piece.position().top)
		left 	= parseFloat(piece.position().left)
		right 	= left + width		# Top-right
		bottom 	= top  + height		# Bottom-left
		
		# Compute the four corners of the piece
		top_left 	= {"x": left, 	"y": top}
		top_right 	= {"x": right, 	"y": top}
		bottom_left = {"x": left, 	"y": bottom}
		bottom_right= {"x": right, 	"y": bottom}
		
		piece.data("position", {
			"top_left"		: top_left,
			"top_right"		: top_right,
			"bottom_left" 	: bottom_left,
			"bottom_right"	: bottom_right
		})
		return	# Void function
		
	findSnappableNeighbors: (current_piece, neighbors_objects, snapping_threshold) ->
	# Purpose:	Determines the snappable neighbors that are within a snapping, pixel tolerance
	# Precond:	neighbors_objects is a list of piece objects neighboring the current piece
	#			snapping_threshold is an integer, lower-bound amount of pixels for snapping between neighbors 
	# Returns:	A list of neighbor ids that are within snapping range
		cp_neighbors_object = current_piece.data("neighbors")
		
		# For the case when the neighbors are out of order in the passed objects list
		neighbors_objects_ids = _.map(neighbors_objects, (n) -> return n.data("id"))
		
		# Find the positional neighbor relation (left, top, bottom, right) for each neighbor
		neighbors_relations = _.map(neighbors_objects_ids, (nid) => 
			# If the value (id) isn't null or undefined then get they key for that value
			if nid? then return @getKeyFromValue(cp_neighbors_object, nid)
		)
		
		snappable = []
		# Determine the IDs of the pieces that are witihin snapping range and in the proper snapping position
		# in reference to the current piece.
		# TODO: Possible use _.zip() to combine the neighbor_objects and position_relations sets into tuples.
		for i in [0 .. neighbors_objects_ids.length - 1]
			neighbor_id 		= neighbors_objects_ids[i]
			neighbor_object 	= neighbors_objects[i]
			neighbor_relation 	= neighbors_relations[i]
			
			snaps = @canSnap(current_piece, neighbor_object, neighbor_relation, snapping_threshold)
			if snaps
				snappable.push neighbor_id
				
		return snappable
	
	getKeyFromValue: (obj, value) ->
	# Purpose: 	Helper that finds and returns the first key from the passed object with a value matching the passed value.
	# Returns:	The key with the matching value.
	# Usage:	getKeyFromValue({1: "some", 2: "related", 3: "val"}, "val")  	returns 3
		keys = _.keys(obj)
		desired_key = _.find(keys, (k) -> return obj[k] == value)   
		return desired_key
		
	canSnap: (current_piece, neighbor_object, neighbor_relation, snapping_threshold) ->
	# Purpose: 	Determines if the neighbor is within snapping distance
	#			and snapping orientation about the current piece.
	# Returns:	True if the neighbor is snappable. False otherwise.
	# Note:		We're relying on the detailed positional data since it also includes bottom and right
	#			which are valid snappable orientations.	
		cp = current_piece.data("position")
		np = neighbor_object.data("position")
		
		# Holds the points to be used in determine if snapping is possible 
		points = []
		
		# The orientation of the neighbor about the piece in the original board. 
		#	i.e., was the neighbor to the right, left, top, or bottom of the current piece?
		switch neighbor_relation
			
			# If you're my right neighbor
			# Then my right side must be within range of your left side
			when "right" 	then points = [cp.top_right, cp.bottom_right, np.top_left, np.bottom_left]
			
			# If you're my left neighbor
			# Then my left side must be within range of your right side
			when "left" 	then points = [cp.top_left, cp.bottom_left, np.top_right, np.bottom_right]
			
			# If you're my top neighbor
			# Then my top side must be within range of your bottom side
			when "top" 		then points = [cp.top_left, cp.top_right, np.bottom_left, np.bottom_right]
			
			# If you're my bottom neighbor
			# Then my bottom side must be within range of your top side
			when "bottom" 	then points = [cp.bottom_left, cp.bottom_right, np.top_left, np.top_right]
		
		snappable = @isWithinThreshold(points[0], points[1], points[2], points[3], snapping_threshold)		
		return snappable
	
	isWithinThreshold: (cp1, cp2, np1, np2, snapping_threshold) ->
	# Purpose: 	Determines if the Euclidean distance between passed associated points are within the snapping
	# Precond:	cp1 compares to n1, cp2 compares to n2
	#			points are objects with an x and y value
	# Returns:	True if the both distances between the sets of points are within the threshold
	
		# TODO: The distance between points is symmetrical due to the equi-sized, square nature of the pieces
		#		The distance between one set of points should be enough to determine snapping ability
		
		dist1 = @manhattanDistance(cp1.x, cp1.y, np1.x, np1.y)
		dist2 = @manhattanDistance(cp2.x, cp2.y, np2.x, np2.y)
		
		is_within = dist1 <= snapping_threshold && dist2 <= snapping_threshold
		return is_within
		
	euclideanDistance: (x1, y1, x2, y2) ->
	# Purpose: 	Computes the euclidean distance of the passed points
	# Returns: 	The floating point distance
		xs = Math.pow((x2 - x1), 2)
		ys = Math.pow((y2 - y1), 2)
		return Math.sqrt(xs + ys)
	
	manhattanDistance: (x1, y1, x2, y2) ->
	# Purpose: 	Computes the manhattan distance of the passed points
	# Returns: 	The floating point distance
		xs = Math.abs(x2 - x1)
		ys = Math.abs(y2 - y1)
		return xs + ys
		
	initNeighbors: (rows, columns, board) ->
	# Purpose:	Creates a neighbor (top, bottom, left, and right) hash for each (piece) board position
	# Returns:	An object of board index -> neighbor indices object 
	# Notes: 	This creates a lookup table that can save us from traversing the board to find the neighbors 
	#			for a given piece on every mouseup event (drag end).
	# 			We're leveraging the fact that seg faults are masked as "undefined." If a neighbor is undefined, then 
	#			the current piece is on the boundary of the board.
	# Board boundary indices
	# 			top				
	# left	---------------	right
	# 		|	   |	  |
	#		---------------
	# 		|	   |	  |
	#		---------------
	# 			bottom
		neighbors = {}
		
		left_bound 		= 0
		top_bound		= 0
		right_bound 	= columns - 1 
		bottom_bound	= rows - 1
		
		for row in [0 .. rows - 1]			
			# We want border positions to have undefined neighbors
			left 	= undefined
			right 	= undefined
			top 	= undefined
			bottom 	= undefined	
			# Grab the IDs of the neighbors
			for col in [0 .. columns - 1]				
				# Avoid boundaries. Can't access subelement of undefined...				
				left   = if (col != left_bound) then board[row][col - 1]
				top    = if (row != top_bound)  then board[row - 1][col]
					
				right  = if (col != right_bound)  then board[row][col + 1]
				bottom = if (row != bottom_bound) then board[row + 1][col]
		
				current_position_id = board[row][col]
		
				# Set the current board position's neighbors
				neighbors[current_position_id] = {"left": left, "right": right, "top": top, "bottom": bottom}
		
		return neighbors
				 
	initPieces: (rows, columns, back_canvas, starting_id, neighbors) ->
	# Purpose:	Creates a list of pieces/sub-canvases that represent a portion of the back canvas.
	# Precond:	back_canvas - an HTML5 Canvas Element whose dimensions are used to determine piece dimensions.
	# Note:		Pieces are currently rectangular shapes about the back canvas.
	# Returns:	An object of id -> pieces/canvas object hashes
	
		pieces = {}
		next_id = starting_id
		
		back_width = back_canvas.width()
		back_height = back_canvas.height()
		
		# The max dimensions for each piece
		piece_width  = back_width / columns
		piece_height = back_height / rows
		
		cur_row_top     = 0
		cur_column_left = 0
		
		num_pieces_needed = rows * columns
		
		for i in [1 .. num_pieces_needed]							
			# The coordinates of the current piece about the back canvas
			videox = cur_column_left
			videoy = cur_row_top
			
			# Grab the list of neighbors for the current piece to be generated
			neighbor_hash = neighbors[next_id]
			piece = @createPiece(next_id, piece_width, piece_height, videox, videoy, neighbor_hash)
			# Add the current piece to the hash
			pieces[next_id] = piece
			
			next_id++
			# After creation, set up the starting position for the next piece
			cur_column_left += piece_width
			
			# Check how far we're moving to the right	
			should_move_to_next_row = cur_column_left >= back_width
			if should_move_to_next_row				
				cur_row_top += piece_height
				cur_column_left = 0
				
		return pieces
		
	createPiece: (id, width, height, videox, videoy, neighbors) ->
	# Purpose: 	Initializes a subcanvas with the passed dimensions
	# Preconds:	videox and videoy are the piece's position atop the back canvas playing the video
	#			originx and originy are the piece's location
	# 			neighbors is a hash of positions -> ids of canvas elements the piece should snap to
	# Returns: 	A populated canvas instance 
		
		# TODO: Generate a random top and left location for the piece and use movePiece() with the generated location.
		# 		This will mean that the pieces start randomized and don't move into place. We'd have to trigger piece creation during the
		#		start of movie playback if we want that type of transition.
				
		piece = $("<canvas></canvas>").clone()
		piece.attr({
			'width'	: width,
			'height': height,
			'videox': videox,
			'videoy': videoy
			})			
			.css("cursor", "pointer")
			.data("id", id)						# Keeps ID hidden from user
			.data("neighbors", neighbors)		# List of neighbors by canvas id
			.data("group", -1)					# Default group id. Group used for snapping multiple pieces together.
			.appendTo('#pieces-canvas')			# FIXME: This breaks if we change the div name...
			.addClass("piece")					# Added for ease of finding similar objects
		
		return piece
	
			
	movePiece: (piece, x, y) ->
	# Purpose:	Animates the passed piece to the passed location.
	# Precond:	piece is a jquery canvas object
	# Notes:	uses jquery animate with a predefined duration
	# TODO: This should be a member of a Piece class.
		piece.animate({
		'left' : x,
		'top' : y
		}, 1900)	
				
	initBoard: (rows, columns, starting_id) ->
	# Purpose: 	Creates a num_rows x num_columns matrix of IDs.
	# Notes: 	This is used to keep track of adjacency about the pieces in the game.
	# 			IDs range from starting_id to rows * columns
	# Returns: 	A 2D array of IDs.
		board = []
		next_id = starting_id
		
		for i in [0 .. rows - 1]
			board[i] = []
			for j in [0 .. columns - 1]
				board[i].push(next_id)
				next_id++
		return board
		
	renderVideoToBackCanvas: (video_element, back_canvas_context, refresh_rate, pieces)->
	# Purpose: 	Renders the playing video (via the video_element) to the back canvas
	# Precond:	refresh_rate is the millisecond delay between render calls.
	# FIXME:	pieces is initialized in this function when the video is actually playing
	# NOTE: 	FPS = 1000 ms / refresh_rate
	# 			drawimage() only works for VideoElement, Canvas, of ImageElement
	# TODO: Look into requestAnimationFrame() to replace setInterval()
		setInterval => 
			# Advance the video to provide new frames
			video_element.play()		   
			# Render the video to the back canvas
			back_canvas_context.drawImage(video_element, 0, 0)		
		, refresh_rate

	renderBackCanvasToPieces: (back_canvas_element, pieces, refresh_rate) ->
	# Purpose:	Renders the frame from the back canvas to the pieces canvas.
	# Precond:	pieces is a hash of an id -> piece object 
		pieces_objects = _.values(pieces)
		
		setInterval => 	   
			#debugger
			_.each(pieces_objects, (piece) ->
				piece_context = piece[0].getContext('2d')
				# TODO: Maybe use piece.getAttributes() and use access operator for speed
				videox  = parseFloat(piece.attr("videox"))
				videoy  = parseFloat(piece.attr("videoy"))
				width   = parseFloat(piece.attr("width"))
				height  = parseFloat(piece.attr("height"))
			
				# Render the proper portion of the back canvas to the current piece
				piece_context.drawImage(back_canvas_element, videox, videoy, width, height, 0, 0, width, height)
			)							
		, refresh_rate
$ ->
	window.jigsaw = new Jigsaw()