class @PieceManager
# Represents a collection of helper functions manipulation of multiple pieces.
	@initPieces: (rows, columns, back_canvas, starting_id, neighbors) ->
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
			#piece = @createPiece(next_id, piece_width, piece_height, videox, videoy, neighbor_hash)
			piece = Piece.createPiece(next_id, piece_width, piece_height, videox, videoy, neighbor_hash)
			
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
	
	@randomize: (pieces) ->
	# Purpose: Randomize the top and left positions of each piece in the passed list 
	#			and animates them to their new positions
		offset = 100 	# Nudge factor
		center_pos = "x" : ($(window).width() / 2) - offset, "y": $(window).height() / 2
		
		# List of objects with an left (x) and top (y) value
		num_points = _.size(pieces)
		radius = 300
		points = MathHelper.generatePointsAboutCircle(num_points, center_pos, radius)
		
		# Shuffle the points
		indices = [0 ... num_points]
		indices = _.shuffle(indices)
		
		for i in [0 ... num_points]
			#FIXME: See if we can use "for p in pieces"
			p	= pieces[i + 1]	# Piece indices start at 1
			ind = indices[i]
			circle_point= points[ind]
			
			# Set the top and left to the point's y and x, respectively
			@movePiece(p, circle_point.x, circle_point.y, 400)
			