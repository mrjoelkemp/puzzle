class @Piece
# Represents a subcanvas object that renders a portion of a playing video.

	constructor: (id, width, height, videox, videoy, neighbors) ->
		@create(id, width, height, videox, videoy, neighbors)


	create: (id, width, height, videox, videoy, neighbors) ->
	# Purpose: 	Initializes a subcanvas with the passed dimensions
	# Preconds:	videox and videoy are the piece's position atop the back canvas playing the video
	#			originx and originy are the piece's location
	# 			neighbors is a hash of positions -> ids of canvas elements the piece should snap to

		# TODO: Generate a random top and left location for the piece and use movePiece() with the generated location.
		# 		This will mean that the pieces start randomized and don't move into place. We'd have to trigger piece creation during the
		#		start of movie playback if we want that type of transition.
				
		@piece = $("<canvas></canvas>").clone()
		@piece.attr({
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