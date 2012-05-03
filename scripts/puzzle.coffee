class @Jigsaw
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
		board = Board.initBoard(rows, columns, starting_id)
		
		# Generate a lookup table for finding a piece's list of neighbors
		neighbors = @initNeighbors(rows, columns, board)
		
		# We pass the board to tell pieces who they snap to
		#pieces = @initPieces(rows, columns, back_canvas, starting_id, neighbors)
		pieces = PieceManager.initPieces(rows, columns, back_canvas, starting_id, neighbors)
		
		# Pixel distance for snapping between neighbors
		snapping_threshold = 40
		# Set up the draggable actions and events for each piece
		@setDraggingEvents(pieces, snapping_threshold)
		
		# Randomize piece locations
		PieceManager.randomize(pieces)
		
		# The refresh delay between setInterval() calls
		refresh_rate = 33
		back_canvas_element = back_canvas[0]
		back_canvas_context = back_canvas_element.getContext('2d')	
		RenderHelper.renderVideoToBackCanvas(video_element, back_canvas_context, refresh_rate)
		RenderHelper.renderBackCanvasToPieces(back_canvas_element, pieces, refresh_rate)
					
	setDraggingEvents: (pieces, snapping_threshold) ->
	# Purpose: 	Initializes the dragging events for each piece in the passed list
		_.each(pieces, (piece) =>	# Avoid the piece's context
			piece.draggable({
				helper 	: "original",				# Drag the original object, not a clone or anything else
				snap	: false,					# Turn off snapping until we manually trigger snapping
				snapMode: "inner",
				stack	: ".piece",					# Dragged piece has a higher z-index
				snapTolerance: snapping_threshold	# Pixel distance to initiate snapping	
			})	#end draggable()
			piece.bind("dragstart", (e, ui) => Piece.onDragStart(e, ui, piece))
			piece.bind("drag", (e, ui) => Piece.onDrag(e, ui, piece, pieces))
			piece.bind("dragstop", (e, ui) => @onDragStop(piece, pieces, snapping_threshold))
		)
		
	onDragStop: (piece, pieces, snapping_threshold) ->
	# Purpose: 	Handler for drag stop event. 
	# Note:		On the drag stop, snap to the proper pieces and check for game completion.
		# Update detailed positional information for current piece
		Piece.updateDetailedPosition(piece)
		
		# Grab neighboring pieces -- not expensive due to max of 4 neighbors
		neighbors_objects = Piece.getNeighborObjects(piece, pieces)
							
		# Update detailed positional info of neighboring pieces 
		# FIXME: Should this always be a just-in-case, or do the neighbors update their own positions?
		_.each(neighbors_objects, (n) => Piece.updateDetailedPosition(n))
		
		# Find and extract snappable neighbor(s)
		snappable_neighbors_ids = @findSnappableNeighbors(piece, neighbors_objects, snapping_threshold)
		snappable_neighbors = Piece.getNeighborObjectsFromIds(pieces, snappable_neighbors_ids)
		
		# If we found a neighbor to snap to
		have_neighbors_to_snap = not _.isEmpty(snappable_neighbors)
		if have_neighbors_to_snap 			
			# Update neighbors' groups with new group id
			@propagateSnap(piece, snappable_neighbors, pieces)
			# Snap to immediate, snappable neighbors
			@snapToNeighbors(piece, snappable_neighbors)

			# If a snap occurs, then check for game win
			@checkWinCondition(pieces)

	checkWinCondition: (pieces) ->
	# Purpose: 	Checks if the game's win condition has been satisfied
	# Notes: 	Win condition occurs when every piece belongs to the same group. 
	#			i.e., all of the pieces are snapped together.
		num_pieces = _.size(pieces)

		# Grab the group id of the first piece
		# Since every piece has to be in the same group, this is okay
		g_id = pieces[1].data("group")

		# Get the group members that have the same group id
		group_members = _.filter(pieces, (p) -> return p.data("group") == g_id)

		game_won = num_pieces == _.size(group_members)
		
		if(game_won)
			@updateGameStatus("You Win!")

	updateGameStatus: (msg) ->
	# Purpose: Updates the game status message element with the passed message
		$('#game-status').html("<span>" + msg + "</span>")
						 .addClass("win")

	propagateSnap: (piece, snappable_neighbors, pieces) ->	
	# Purpose:	Propagates a group id change through the current piece's neighbors 
	#			and the neighbors of the snappable_neighbors 
		# The new group ID
		# Note: We just use the piece's id as the group id
		p_gid = piece.data("id")
		# Set the piece's own group id
		piece.data("group", p_gid)

		# For each snappable neighbor, get its group members
		_.each(snappable_neighbors, (n) =>
			# Neighbor's existing group id
			n_gid = n.data("group")

			has_group = n_gid != -1
			if has_group
				# Get the group members
				n_group_members = Piece.getGroupObjects(n_gid, n, pieces)

				# Change the group id for each member to the current piece's group id
				_.each(n_group_members, (ngm) -> ngm.data("group", p_gid))
		)

		# Modify the group id of the snappable_neighbors
		_.each(snappable_neighbors, (sn) -> sn.data("group", p_gid))

	debug_colorObjectsFromId: (pieces) ->
	# Purpose: 	Helper to visualize group membership changes
	# TODO: 	Delete!!
		colors = ["red", "green", "blue", "yellow", "black", "pink"]		
		
		# Change the neighbors' group id
		_.each(pieces, (p) -> 
			p_gid = p.data("group")
			p.css("border", "3px solid " + colors[p_gid])
		)
	
	snapToNeighbors: (current_piece, snappable_neighbors) ->
	# Purpose: 	Snaps the current piece to the snappable neighbors and adds them all to the same drag group.
	# Note:		The neighbors join the current piece's group which makes group membership dynamic.
	
		# Get the relation of the neighbors about the current piece (left, right, top, bottom)
		neighbors_relations = Piece.getNeighborRelations(current_piece, snappable_neighbors)
		
		# Combine the two sets of information so we can iterate
		objects_relations = _.zip(snappable_neighbors, neighbors_relations)
		
		# Grab a list of 4 snappable points for each neighbor in relation to the current piece
		# 	the first 2 elements are the snappable points for the current piece
		#	the last 2 elements are the snappable points for the neighbor based on their relationship (right, left, top, or bottom)
		neighbors_points = _.map(objects_relations, (arr) => 
			neighbor = arr[0]
			relation = arr[1]
			@getSnappablePoints(current_piece, neighbor, relation)
		)
		
		# Compute the amount of pixels the current piece should move in both directions (top and left)
		_.each(neighbors_points, (points) =>
			offsets 	= Piece.getMovementOffset(points[0], points[1], points[2], points[3])
			left_offset = offsets.left_offset
			top_offset 	= offsets.top_offset
			
			Piece.movePieceByOffsets(current_piece, left_offset, top_offset, 0)
		)
	
	findSnappableNeighbors: (current_piece, neighbors_objects, snapping_threshold) ->
	# Purpose:	Determines the snappable neighbors that are within a snapping, pixel tolerance
	# Precond:	neighbors_objects is a list of piece objects neighboring the current piece
	#			snapping_threshold is an integer, lower-bound amount of pixels for snapping between neighbors 
	# Returns:	A list of neighbor ids that are within snapping range
		
		# Find the positional neighbor relation (left, top, bottom, right) for each neighbor
		neighbors_relations = Piece.getNeighborRelations(current_piece, neighbors_objects)
		
		snappable = []
		
		neighbors_objects_ids = _.map(neighbors_objects, (n) -> return n.data("id"))
				
		# Determine the IDs of the pieces that are witihin snapping range and in the proper snapping position
		# in reference to the current piece.
		# TODO: Possible use _.zip() to combine the neighbor_objects and position_relations sets into tuples.
		for i in [0 .. neighbors_objects_ids.length - 1]
			neighbor_id 		= neighbors_objects_ids[i]
			neighbor_object 	= neighbors_objects[i]
			neighbor_relation 	= neighbors_relations[i]
			
			snaps = @canSnap(current_piece, neighbor_object, neighbor_relation, snapping_threshold)
			if snaps then snappable.push neighbor_id
				
		return snappable
			
	canSnap: (current_piece, neighbor_object, neighbor_relation, snapping_threshold) ->
	# Purpose: 	Determines if the neighbor is within snapping distance
	#			and snapping orientation about the current piece.
	# Returns:	True if the neighbor is snappable. False otherwise.
	# Note:		We're relying on the detailed positional data since it also includes bottom and right
	#			which are valid snappable orientations.	
		# Get the points that can snap together from the two pieces based on their relationship
		points = @getSnappablePoints(current_piece, neighbor_object, neighbor_relation)
		
		# Holds the points to be used in determine if snapping is possible 
		snappable = MathHelper.isWithinThreshold(points[0], points[1], points[2], points[3], snapping_threshold)		
		return snappable
		
	getSnappablePoints: (current_piece, neighbor_piece, neighbor_relation) ->
	# Purpose: Determines the points from the two pieces that are important for snapping based on the passed relation
	# Returns: A 4-element list containing the points of interest from both pieces. 2 from current_piece and 2 from neighbor.
		cp = current_piece.data("position")
		np = neighbor_piece.data("position")
		
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
		
		return points		
		
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
				 					
