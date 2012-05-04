HTML5 Video Puzzle
======
Created by: Joel Kemp, @mrjoelkemp

Built using: Coffeescript, Underscore.js, HTML5, HAML/SASS, JQuery UI, Head.js

JSFiddle: http://jsfiddle.net/dGGcZ/1/embedded/result/

# Notes

## Dependencies
Head.js: 	Used for parallel fetching of the necessary (compiled) javascripts.

Jquery UI: 	This implementation heavily leveraged the Draggable interface.

Underscore.js: 	I absolutely love the expressive power of underscore!

## Abstractions
Ideally, a Piece should be a canvas element or an extension of a Jquery object. This was not attempted as it would warrant a complete rewrite.

Instead, the classes Puzzle, Piece, PieceManager, Board, MathHelper, and RenderHelper all consist of static properties that abstract code away from puzzle.coffee. This isn't the cleanest implementation, but it will suffice.

## Group Dragging
Group dragging is a little buggy; I believe this is due to the timing of the event firing in Jquery UI's draggable interface. 

An alternative implementation that I had in mind for group drag:

Each piece contains a super-imposed, draggable bounding box where a clone of each snapped neighbor would be added -- and hence, draggable alongside the current piece. As more pieces snapped together, the bounding box would grow. This dynamic management of a bounding box is a headache!

The aforementioned solution might not work due to the fact that the pieces (subcanvases) are already appended to the pieces-canvas; hence, a clone would have to be added to a piece's bounding box. Clones would create copies of the objects and could result in significant rendering slow-downs.

# Disclaimer
This code may not be used for commercial purposes.
