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
		debugger
		# Generate a lookup table for finding a piece's list of neighbors
		neighbors = @initNeighbors(rows, columns, board)
		
		# We pass the board to tell pieces who they snap to
		pieces = @initPieces(rows, columns, back_canvas, starting_id, neighbors)
				
		# Set up the draggable actions and events for each piece
		@setDraggingEvents(pieces)
	
		# The refresh delay between setInterval() calls
		refresh_rate = 33
		back_canvas_element = back_canvas[0]
		back_canvas_context = back_canvas_element.getContext('2d')	
		@renderVideoToBackCanvas(video_element, back_canvas_context, refresh_rate)
		@renderBackCanvasToPieces(back_canvas_element, pieces, refresh_rate)
	
	setDraggingEvents: (pieces) ->
	# Purpose: 	Initializes the dragging events for each piece in the passed list
		_.each(pieces, (piece) ->
			piece.draggable({
				snap	: false,
				snapMode: "inner",
				stack	: ".piece",				# Dragged piece has a higher z-index
				snapTolerance: 20,				# Pixel distance to initiate snapping
				opacity: 0.75,					# Make the dragged piece lighter for now. TODO: Remove when we have collision detection.
				start	: (e, ui) ->
					# Remember where you are so the movement distance can be computed
					piece.data("old_top", piece.position().top)
					piece.data("old_left", piece.position().left)
				drag	: (e, ui) ->
					# Drag every (snapped) piece in the group
					# dragGroup(group_id)
				stop	: (e, ui) ->
					# Find neighbors within the board matrix
					#findCloseNeighbors(piece, neighbors)
					#snapToCloseNeighbors(piece, neighbors)
										
					# Check for a win condition: all pieces are snapped together
					
			})	#end draggable()
		)
		
	initNeighbors: (rows, columns, board) ->
		# Purpose:	Creates a neighbor (top, bottom, left, and right) hash for each (piece) board position
		# Returns:	A hash or board index -> neighbor indices object 
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
	# Returns:	A list of pieces/canvas objects
	
		pieces = []
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
			pieces.push(piece)
			
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
	
	findCloseNeighbors: (piece, neighbors) ->
	# Purpose:	Determines the snappable neighbors that are within a snapping, pixel tolerance
	# Precond:	neighbors is an object with position -> id mappings
	# Returns:	A list of neighbor ids that are within snapping range
		# Get neighbor ids
		ids = _.values(neighbors)
		positions = _.each(ids, (id)) 
		# For each neighbor
		_.filter(neighbors, (n) ->
			# Get neighbor id
			
			# Get neighbor position
			
			)
		# Determine how close a neighbor is and then check for snapping? Or is there a way to tell Jquery about an inner snapping distance
		
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
	#			pieces is initialized in this function when the video is actually playing
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
		setInterval => 	   
			#debugger
			for i in [0 .. pieces.length - 1]
				piece = pieces[i]
				piece_context = piece[0].getContext('2d')
				# TODO: Maybe use piece.getAttributes() and use access operator for speed
				videox  = parseFloat(piece.attr("videox"))
				videoy  = parseFloat(piece.attr("videoy"))
				width   = parseFloat(piece.attr("width"))
				height  = parseFloat(piece.attr("height"))
			
				# Render the proper portion of the back canvas to the current piece
				piece_context.drawImage(back_canvas_element, videox, videoy, width, height, 0, 0, width, height)							
		, refresh_rate
$ ->
	window.jigsaw = new Jigsaw()