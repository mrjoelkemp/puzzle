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

	####################
	#	Drag Helpers
	####################
	
	@onDragStart: (e, ui, piece) ->
	# Purpose: 	Handler for drag start event
	# Precond: 	The ui is the helper object that's being dragged. Its positional info is more accurate than the piece's position.
		# Remember where you are so the movement distance can be computed during drag
		@updateOldPosition(piece, ui.offset)		

	@onDrag: (e, ui, piece, pieces) ->
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
		
	@dragGroup:(group_id, piece, pieces, offset_obj) ->
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

	
	####################
	#	Updaters
	####################

	@updateDetailedPosition: (piece) ->
	# Purpose: 	Updates the hidden positional (top, left, bottom, right) data of the passed piece
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

	@updateOldPosition: (piece, ui_offset) ->
	# Purpose: 	Updates the custom data field with old positional data
	# Notes:	Used to keep track of distance travelled between drag events
		piece.data("old_top", parseFloat(ui_offset.top))
		piece.data("old_left", parseFloat(ui_offset.left))
	
	@setPositionByOffsets: (piece, left_offset, top_offset) ->
	# Purpose: 	Simply sets the top and left css positions of the passed piece to its current location plus the offsets
		#debugger
		top  = parseFloat(piece.css("top"))
		left = parseFloat(piece.css("left"))
		
		new_left = left + left_offset
		new_top  = top  + top_offset 
		
		piece.css("left", new_left)
		piece.css("top", new_top)
	
	####################
	#	Getters
	####################

	@getMovementOffset: (cp1, cp2, np1, np2) ->
	# Purpose: 	Computes the difference between 
	# Returns:	An object with the two offsets		
		# Distance (top and left) from the neighbor to the piece
		ntop_to_ptop 	= np1.y - cp1.y
		nleft_to_pleft 	= np2.x - cp2.x
		 
		return "top_offset": ntop_to_ptop, "left_offset": nleft_to_pleft

	@getGroupObjects: (group_id, piece, pieces) ->
	# Purpose: 	Finds the pieces that belong to the group with the passed group_id. Excludes the current piece from the group.
	# Returns:	A list of pieces within the group.
		# Find group neighbors
		group_objects = _.filter(pieces, (p) -> return p.data("group") == group_id)

		# Exclude the current piece from that group since we only want to drag neighbors
		group_objects = _.reject(group_objects, (p) -> return p.data("id") == piece.data("id"))
		return group_objects
	
	@getNeighborObjectsFromIds: (pieces, neighbors_ids) ->
	# Purpose: 	Extracts the neighbor objects from the pieces list with ids matching passed neighbor ids
	# Returns:	A list of neighbor (piece) objects
		neighbors_pieces = _.map(neighbors_ids, (id) -> return pieces[id])
		return neighbors_pieces

	@getNeighborRelations: (current_piece, neighbors_objects) ->	
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
	
	@getKeyFromValue: (obj, value) ->
	# Purpose: 	Helper that finds and returns the first key from the passed object with a value matching the passed value.
	# Returns:	The key with the matching value.
	# Usage:	getKeyFromValue({1: "some", 2: "related", 3: "val"}, "val")  	returns 3
		keys = _.keys(obj)
		desired_key = _.find(keys, (k) -> return obj[k] == value)   
		return desired_key	
	
	@getNeighborObjects: (current_piece, pieces) ->
	# Purpose:	Extracts the neighboring piece objects for the passed current piece
	# Returns: 	A list of neighbor piece objects.
		neighbors_obj = current_piece.data("neighbors")
		neighbors_ids = _.values(neighbors_obj)
		
		# Remove the undefined ids for boundary pieces
		neighbors_ids = _.compact(neighbors_ids)
		
		# Grab pieces associated with neighbor ids
		neighbors_pieces = Piece.getNeighborObjectsFromIds(pieces, neighbors_ids)
		
		return neighbors_pieces

	####################
	#	Movement Helpers
	####################

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