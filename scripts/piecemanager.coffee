class @PieceManager
	constructor: (board_dimensions, piece_dimensions, neighbors) ->
	
	initPieces: (board_dimensions, piece_dimensions, neighbors) ->

		starting_id	= 1

		piece_width  = piece_dimensions.width
		piece_height = piece_dimensions.height

		rows = board_dimensions.rows
		cols = board_dimensions.columns