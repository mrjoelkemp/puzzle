class Jigsaw
	constructor: ->
		rows = 2
		columns = 3
		
		back_canvas = $('#back-canvas')
		back_canvas_context = back_canvas[0].getContext('2d')

		player = $('#player')
		video_element = $('#player')[0]
		video_element.muted = true

		setInterval => 
			video_element.play()
		    # drawimage() only works for VideoElement, Canvas, of ImageElement
			back_canvas_context.drawImage(video_element, 0, 0)   
		, 33
	
$ ->
	window.jigsaw = new Jigsaw()