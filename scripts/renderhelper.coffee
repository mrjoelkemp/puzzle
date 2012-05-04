class @RenderHelper
	@renderVideoToBackCanvas: (video_element, back_canvas_context, refresh_rate, pieces)->
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

	@renderBackCanvasToPieces: (back_canvas_element, pieces, refresh_rate) ->
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