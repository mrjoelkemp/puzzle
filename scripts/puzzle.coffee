class @Jigsaw
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
		neighbors = Board.initNeighbors(rows, columns, board)
		
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
		snappable_neighbors_ids = Piece.findSnappableNeighbors(piece, neighbors_objects, snapping_threshold)
		snappable_neighbors = Piece.getNeighborObjectsFromIds(pieces, snappable_neighbors_ids)
		
		# If we found a neighbor to snap to
		have_neighbors_to_snap = not _.isEmpty(snappable_neighbors)
		if have_neighbors_to_snap 			
			# Update neighbors' groups with new group id
			Piece.propagateSnap(piece, snappable_neighbors, pieces)
			# Snap to immediate, snappable neighbors
			Piece.snapToNeighbors(piece, snappable_neighbors)

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