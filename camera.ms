// This module manages the "camera", i.e., the scrolling
// of all displays as needed to keep the player in view.

import "importUtil"
ensureImport "level"
ensureImport "background"
ensureImport "spriteControllers"
ensureImport "lava"

camBox = {}
camBox.left = 100
camBox.right = 580
camBox.bottom = 320
camBox.top = 500

// Scroll as needed to get x,y (in world coordinates)
// to be within camBox (in screen coordinates).
update = function(x, y)
	sx = level.disp.scrollX
	sy = level.disp.scrollY
	if x - sx < camBox.left then
		sx = x - camBox.left
	else if x - sx > camBox.right then
		sx = x - camBox.right
	end if
	if y - sy < camBox.bottom then
		sy = y - camBox.bottom
	else if y - sy > camBox.top then
		sy = y - camBox.top
	end if
	if sx < 0 then
		sx = 0
	else if sx + 960 > level.disp.extent[0] * 64 then
		sx = level.disp.extent[0] * 64 - 960
	end if
	if sy < 0 then
		sy = 0
	else if sy > 320 then
		sy = 320
	end if
	if sx != level.disp.scrollX or sy != level.disp.scrollY then
		scrollTo sx, sy
	end if
end function

scrollTo = function(sx, sy)
	level.disp.scrollX = sx
	level.disp.scrollY = sy
	displays.stoneDisp.scrollX = sx
	displays.stoneDisp.scrollY = sy
	lava.disp.scrollX = sx
	lava.disp.scrollY = sy
	spriteControllers.disp.scrollX = sx
	spriteControllers.disp.scrollY = sy
	background.scrollTo sx, sy
end function

reset = function
	scrollTo 0,0
end function

