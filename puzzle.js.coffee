class Jigsaw
	constructor: ->
		# Back canvas renders the video
		back_canvas = $('#back-canvas')
		back_canvas_context = back_canvas[0].getContext('2d')	
		# Pieces canvas consists of smaller canvases that are each rendering parts of the back_canvas	
		pieces_canvas = $("#pieces-canvas")
		
		# Dimensions of the board
		rows = 2
		columns = 3
				
		# The max dimensions for each piece
		piece_width = back_canvas.width() / columns
		piece_height = back_canvas.height() / rows
		
		# Initialize a 2D board to retain neighbor information for snapping
		board = []
		for i in [0 .. rows - 1]
			board[i] = []
			for j in [0 .. columns - 1] 
				# TODO: Compute the top and left positions of the current piece
				cur_top = 0
				cur_left = 0
				
				piece = $("<canvas></canvas>").clone()
				piece.attr({
					'width': piece_width,
					'height': piece_height,
					'top': cur_top,
					'left': cur_left
				})
	
				piece.appendTo('#pieces-canvas')
				board[i].push(piece)
		
		
		# Prep the back canvas and video

		player = $('#player')
		video_element = $('#player')[0]
		# FIXME: Remove this
		video_element.muted = true
		
		# Render Loop
		setInterval => 
			# Advance the video to provide new frames
			video_element.play()
		    # NOTE: drawimage() only works for VideoElement, Canvas, of ImageElement
			# Render the video to the back canvas
			back_canvas_context.drawImage(video_element, 0, 0)   
			# TODO: Render the back canvas to the pieces
			
		, 33
	
$ ->
	window.jigsaw = new Jigsaw()