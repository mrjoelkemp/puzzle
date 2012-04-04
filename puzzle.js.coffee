class Jigsaw
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
		board = @initBoard(rows, columns, starting_id)
		pieces = @initPieces(rows, columns, back_canvas, starting_id)		
		
	
		# The refresh delay between setInterval() calls
		refresh_rate = 33
		back_canvas_element = back_canvas[0]
		back_canvas_context = back_canvas_element.getContext('2d')	
		@renderVideoToBackCanvas(video_element, back_canvas_context, refresh_rate)
		@renderBackCanvasToPieces(back_canvas_element, pieces, refresh_rate)
		
	initPieces: (rows, columns, back_canvas, starting_id) ->
	# Purpose:	Creates a list of pieces/sub-canvases that represent a portion of the back canvas.
	# Precond:	back_canvas - an HTML5 Canvas Element whose dimensions are used to determine piece dimensions.
	# Note:		Pieces are currently rectangular shapes about the back canvas.
	# Returns:	A list of pieces/canvas objects
	
		pieces = []
		next_id = starting_id
		
		# The max dimensions for each piece
		piece_width  = back_canvas.width() / columns
		piece_height = back_canvas.height() / rows
		
		# Since we're using a list, we need to know when to move the piece's top to the next row
		# Ultimately, the pieces use their top and left to know which part of the video to render
		back_canvas_top  = back_canvas.position().top
		back_canvas_left = back_canvas.position().left		
		
		# FIXME: Clean this up
		pieces_canvas = $("#pieces-canvas")
		pieces_top = pieces_canvas.position().top
		pieces_left = pieces_canvas.position().left
		
		cur_row_top     = 0
		cur_column_left = 0
		
		num_pieces_needed = rows * columns
		for i in [1 .. num_pieces_needed]
			# TODO: Move this logic into createPiece(). Change arguments and params to createPiece(back_canvas, pieces_canvas, rows, columns)
			# The coordinates of the current piece about the back canvas
			videox = back_canvas_left + cur_column_left
			videoy  = back_canvas_top  + cur_row_top
			
			# # The coordinates of the current piece about the pieces canvas
			originx = pieces_left + cur_column_left
			originy = pieces_top + cur_row_top
			
			piece = @createPiece(next_id, piece_width, piece_height, videox, videoy, originx, originy)
			next_id++
			piece.appendTo('#pieces-canvas')
			pieces.push(piece)
			
			# If the index exceeds the last column	
			should_move_to_next_row = i % (columns + 1) == 0
			if should_move_to_next_row
				cur_row_top += piece_height
				cur_column = 0
			else
				cur_column_left += piece_width
				
		return pieces
		
	createPiece: (id, width, height, videox, videoy, originx, originy) ->
	# Purpose: 	Initializes a subcanvas with the passed dimensions
	# Preconds:	videox and videoy are the piece's position atop the back canvas playing the video
	#			originx and originy are the piece's location
	# Returns: 	A populated canvas instance 
		piece = $("<canvas></canvas>").clone()
		piece.attr({
			'id': id,
			'width': width,
			'height': height,
			'videox': videox,
			'videoy': videoy,
			'originx': originx,
			'originy': originy
		})
		
		return piece
		
	initBoard: (rows, columns, starting_id) ->
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
		
	renderVideoToBackCanvas: (video_element, back_canvas_context, refresh_rate, pieces)->
	# Purpose: 	Renders the playing video (via the video_element) to the back canvas
	# Precond:	refresh_rate is the millisecond delay between render calls.
	#			pieces is initialized in this function when the video is actually playing
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
		setInterval => 	   
			debugger
			for i in [0 .. pieces.length - 1]
				piece = pieces[i]
				piece_context = piece[0].getContext('2d')
				# TODO: Maybe use piece.getAttributes() and use access operator for speed
				videox  = parseFloat(piece.attr("videox"))
				videoy  = parseFloat(piece.attr("videoy"))
				originx = parseFloat(piece.attr("originx"))
				originy = parseFloat(piece.attr("originy"))
				width   = parseFloat(piece.attr("width"))
				height  = parseFloat(piece.attr("height"))
			
				# Render the proper portion of the back canvas to the current piece
				#piece_context.drawImage(back_canvas_element, videox, videoy, width, height, originx, originy, width, height)
				piece_context.drawImage(back_canvas_element, 0, 0)			
		, refresh_rate
$ ->
	window.jigsaw = new Jigsaw()