class Jigsaw
	constructor: ->
		# Din
		rows = 2
		columns = 3
		
		back_canvas = $('#back-canvas')
		back_canvas_context = back_canvas[0].getContext('2d')

		player = $('#player')
		video_element = $('#player')[0]
		video_element.muted = true
		
		# Initialize the pieces
		num_pieces = rows * columns
		pieces = []
		for i in [1..num_pieces]
			pieces.push($("<canvas></canvas>").clone())
		
		# Initialize a 2D board to retain neighbor information for snapping
		board = []
		
		
		# Render Loop
		setInterval => 
			video_element.play()
		    # drawimage() only works for VideoElement, Canvas, of ImageElement
			back_canvas_context.drawImage(video_element, 0, 0)   
		, 33
	
$ ->
	window.jigsaw = new Jigsaw()