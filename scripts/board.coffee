class @Board
# Represents a collection of helpers for the neighborhood matrix (board) 
#	modeling the relationships between pieces

	@initBoard: (rows, columns, starting_id) ->
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

	@initNeighbors: (rows, columns, board) ->
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
				 				