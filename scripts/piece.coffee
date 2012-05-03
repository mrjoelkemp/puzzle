class @Piece
# Represents a collection of static helpers for manipulating a subcanvas 
# object that renders a portion of a playing video.

	@createPiece: (id, width, height, videox, videoy, neighbors) ->
	# Purpose: 	Initializes a subcanvas with the passed dimensions
	# Preconds:	videox and videoy are the piece's position atop the back canvas playing the video
	#			originx and originy are the piece's location
	# 			neighbors is a hash of positions -> ids of canvas elements the piece should snap to

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
			.appendTo('#pieces-canvas')			
			.addClass("piece")					# Added for ease of finding similar objects
		return piece

	@setPositionByOffsets: (piece, left_offset, top_offset) ->
	# Purpose: 	Simply sets the top and left css positions of the passed piece to its current location plus the offsets
		#debugger
		top  = parseFloat(piece.css("top"))
		left = parseFloat(piece.css("left"))
		
		new_left = left + left_offset
		new_top  = top  + top_offset 
		
		piece.css("left", new_left)
		piece.css("top", new_top)
		
	@getMovementOffset: (cp1, cp2, np1, np2) ->
	# Purpose: 	Computes the difference between 
	# Returns:	An object with the two offsets		
		# Distance (top and left) from the neighbor to the piece
		ntop_to_ptop 	= np1.y - cp1.y
		nleft_to_pleft 	= np2.x - cp2.x
		 
		return "top_offset": ntop_to_ptop, "left_offset": nleft_to_pleft

	@movePieceByOffsets: (piece, left_offset, top_offset, move_speed = 0) ->
	# Purpose: 	Adds the piece offsets to the piece's current position
		cp_pos_top 	= parseFloat(piece.css('top'))
		cp_pos_left = parseFloat(piece.css('left'))
		
		new_left = cp_pos_left + left_offset 
		new_top  = cp_pos_top  + top_offset

		@movePiece(piece, new_left, new_top, move_speed)

	@movePiece: (piece, x, y, speed = 1900) ->
	# Purpose:	Animates the passed piece to the passed location.
	# Precond:	piece is a jquery canvas object
	# Notes:	uses jquery animate with a predefined duration
	# TODO: This should be a member of a Piece class.
		piece.animate({
		'left' : x,
		'top' : y
		}, speed)		