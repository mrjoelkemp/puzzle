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
	
	@propagateSnap: (piece, snappable_neighbors, pieces) ->	
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

	####################
	#	Snap Helpers
	####################

	@snapToNeighbors: (current_piece, snappable_neighbors) ->
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
	
	@findSnappableNeighbors: (current_piece, neighbors_objects, snapping_threshold) ->
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
			
	@canSnap: (current_piece, neighbor_object, neighbor_relation, snapping_threshold) ->
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
	
	@getSnappablePoints: (current_piece, neighbor_piece, neighbor_relation) ->
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