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
		#debugger
		# We pass the board to tell pieces who they snap to
		#pieces = @initPieces(rows, columns, back_canvas, starting_id, neighbors)
		pieces = PieceManager.initPieces(rows, columns, back_canvas, starting_id, neighbors)
		
		# Pixel distance for snapping between neighbors
		snapping_threshold = 40
		# Set up the draggable actions and events for each piece
		@setDraggingEvents(pieces, snapping_threshold)
		
		# Randomize piece locations
		@randomize(pieces)
		
		# The refresh delay between setInterval() calls
		refresh_rate = 33
		back_canvas_element = back_canvas[0]
		back_canvas_context = back_canvas_element.getContext('2d')	
		@renderVideoToBackCanvas(video_element, back_canvas_context, refresh_rate)
		@renderBackCanvasToPieces(back_canvas_element, pieces, refresh_rate)
	
	randomize: (pieces) ->
	# Purpose: Randomize the top and left positions of each piece in the passed list 
	#			and animates them to their new positions
	# TODO: Implement a more desired randomization
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
			piece.bind("dragstart", (e, ui) => @onDragStart(e, ui, piece))
			piece.bind("drag", (e, ui) => @onDrag(e, ui, piece, pieces))
			piece.bind("dragstop", (e, ui) => @onDragStop(piece, pieces, snapping_threshold))
		)
		
	onDragStart: (e, ui, piece) ->
	# Purpose: 	Handler for drag start event
	# Precond: 	The ui is the helper object that's being dragged. Its positional info is more accurate than the piece's position.
		# Remember where you are so the movement distance can be computed during drag
		@updateOldPosition(piece, ui.offset)
		

	onDrag: (e, ui, piece, pieces) ->
	# Purpose: 	Handler for the drag event
	# Note:		On drag, move the snapped pieces in the currently dragged piece's group

		dragging_pos = "left": parseFloat(ui.offset.left), "top": parseFloat(ui.offset.top)
		#dragging_pos = "left": parseFloat(ui.), "top": parseFloat(piece.data("old_top"))
		
		# Drag every (snapped) piece in the current piece's group
		group_id = piece.data("group")
		group_exists = group_id != -1
		if group_exists			
									
			# Drag the current piece's group of pieces
			@dragGroup(group_id, piece, pieces, dragging_pos)
			
		# Update the old position for the next update
		@updateOldPosition(piece, ui.offset)
		
	
	updateOldPosition: (piece, ui_offset) ->
		piece.data("old_top", parseFloat(ui_offset.top))
		piece.data("old_left", parseFloat(ui_offset.left))
	
	getGroupObjects: (group_id, piece, pieces) ->
	# Purpose: 	Finds the pieces that belong to the group with the passed group_id. Excludes the current piece from the group.
	# Returns:	A list of pieces within the group.
		# Find group neighbors
		group_objects = _.filter(pieces, (p) -> return p.data("group") == group_id)

		# Exclude the current piece from that group since we only want to drag neighbors
		group_objects = _.reject(group_objects, (p) -> return p.data("id") == piece.data("id"))
		return group_objects

	dragGroup:(group_id, piece, pieces, offset_obj) ->
	# Purpose: 	Computes the distance moved by the piece away from the neighbors and moves the neighbors to remain snapped
	# Precond:	offset_obj = the current drag coordinates (top and left)

		# Find group neighbors
		group_objects = @getGroupObjects(group_id, piece, pieces)

		# How much the piece moved within a single drag update
		drag_top_delta 	= offset_obj.top - piece.data("old_top")
		drag_left_delta = offset_obj.left - piece.data("old_left")
		
		# Move each of the neighbors by the new offsets
		_.each(group_objects, (p) => 
			ptop 	= parseFloat(p.css("top"))
			pleft 	= parseFloat(p.css("left"))

			# Add how far the piece has moved in a single update to the neighbor's position
			new_top = ptop 	+ drag_top_delta
			new_left= pleft + drag_left_delta
			p.css({"top": new_top, "left": new_left})
		)

	movePieceByOffsets: (piece, left_offset, top_offset, move_speed = 0) ->
	# Purpose: 	Adds the piece offsets to the piece's current position
		cp_pos_top 	= parseFloat(piece.css('top'))
		cp_pos_left = parseFloat(piece.css('left'))
		
		new_left = cp_pos_left + left_offset 
		new_top  = cp_pos_top  + top_offset

		@movePiece(piece, new_left, new_top, move_speed)

	onDragStop: (piece, pieces, snapping_threshold) ->
	# Purpose: 	Handler for drag stop event. 
	# Note:		On the drag stop, snap to the proper pieces and check for game completion.
		# Update detailed positional information for current piece
		@updateDetailedPosition(piece)
		
		# Grab neighboring pieces -- not expensive due to max of 4 neighbors
		neighbors_objects = @getNeighborObjects(piece, pieces)
							
		# Update detailed positional info of neighboring pieces 
		# FIXME: Should this always be a just-in-case, or do the neighbors update their own positions?
		_.each(neighbors_objects, (n) => @updateDetailedPosition(n))
		
		# Find and extract snappable neighbor(s)
		snappable_neighbors_ids = @findSnappableNeighbors(piece, neighbors_objects, snapping_threshold)
		snappable_neighbors = @getNeighborObjectsFromIds(pieces, snappable_neighbors_ids)
		
		# If we found a neighbor to snap to
		have_neighbors_to_snap = not _.isEmpty(snappable_neighbors)
		if have_neighbors_to_snap 			
			# Update neighbors' groups with new group id
			@propagateSnap(piece, snappable_neighbors, pieces)
			# Snap to immediate, snappable neighbors
			@snapToNeighbors(piece, snappable_neighbors)

			# DEBUG: Visualize the membership changes
			#@debug_colorObjectsFromId(pieces)
			#_.each(pieces, (p) -> console.log("gid: " + p.data("group")))
			#console.log("---")

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
				n_group_members = @getGroupObjects(n_gid, n, pieces)

				# Change the group id for each member to the current piece's group id
				_.each(n_group_members, (ngm) -> ngm.data("group", p_gid))
		)

		# Modify the group id of the snappable_neighbors
		_.each(snappable_neighbors, (sn) -> sn.data("group", p_gid))

	getNeighborObjectsFromIds: (pieces, neighbors_ids) ->
	# Purpose: 	Extracts the neighbor objects from the pieces list with ids matching passed neighbor ids
	# Returns:	A list of neighbor (piece) objects
		neighbors_pieces = _.map(neighbors_ids, (id) -> return pieces[id])
		return neighbors_pieces

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
		neighbors_relations = @getNeighborRelations(current_piece, snappable_neighbors)
		
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
			offsets 	= @getMovementOffset(points[0], points[1], points[2], points[3])
			left_offset = offsets.left_offset
			top_offset 	= offsets.top_offset
			
			@movePieceByOffsets(current_piece, left_offset, top_offset, 0)
		)
	
	setPositionByOffsets: (piece, left_offset, top_offset) ->
	# Purpose: 	Simply sets the top and left css positions of the passed piece to its current location plus the offsets
		#debugger
		top  = parseFloat(piece.css("top"))
		left = parseFloat(piece.css("left"))
		
		new_left = left + left_offset
		new_top  = top  + top_offset 
		
		piece.css("left", new_left)
		piece.css("top", new_top)
		

	movePiece: (piece, x, y, speed = 1900) ->
	# Purpose:	Animates the passed piece to the passed location.
	# Precond:	piece is a jquery canvas object
	# Notes:	uses jquery animate with a predefined duration
	# TODO: This should be a member of a Piece class.
		piece.animate({
		'left' : x,
		'top' : y
		}, speed)		

	getMovementOffset: (cp1, cp2, np1, np2) ->
	# Purpose: 	Computes the difference between 
	# Returns:	An object with the two offsets		
		# Distance (top and left) from the neighbor to the piece
		ntop_to_ptop 	= np1.y - cp1.y
		nleft_to_pleft 	= np2.x - cp2.x
		 
		return "top_offset": ntop_to_ptop, "left_offset": nleft_to_pleft
		
	getNeighborRelations: (current_piece, neighbors_objects) ->	
	# Purpose: Returns a list of relations of the neighbors about the current piece
	# Returns: A list of positional orientations/relations (left, right, top, bottom)
		cp_neighbors_object = current_piece.data("neighbors")

		# For the case when the neighbors are out of order in the passed objects list
		neighbors_objects_ids = _.map(neighbors_objects, (n) -> return n.data("id"))
		neighbors_objects_ids = _.compact(neighbors_objects_ids)

		# Find the positional neighbor relation (left, top, bottom, right) for each neighbor
		neighbors_relations = _.map(neighbors_objects_ids, (nid) => 
			# If the value (id) isn't null or undefined then get they key for that value
			return @getKeyFromValue(cp_neighbors_object, nid)
		)
		return neighbors_relations
		
	getNeighborObjects: (current_piece, pieces) ->
	# Purpose:	Extracts the neighboring piece objects for the passed current piece
	# Returns: 	A list of neighbor piece objects.
		neighbors_obj = current_piece.data("neighbors")
		neighbors_ids = _.values(neighbors_obj)
		
		# Remove the undefined ids for boundary pieces
		neighbors_ids = _.compact(neighbors_ids)
		
		# Grab pieces associated with neighbor ids
		neighbors_pieces = @getNeighborObjectsFromIds(pieces, neighbors_ids)
		
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
		top_left 	= "x": left, 	"y": top
		top_right 	= "x": right, 	"y": top
		bottom_left = "x": left, 	"y": bottom
		bottom_right= "x": right, 	"y": bottom
		
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
		
		# Find the positional neighbor relation (left, top, bottom, right) for each neighbor
		neighbors_relations = @getNeighborRelations(current_piece, neighbors_objects)
		
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