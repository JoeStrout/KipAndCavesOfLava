// Title screen / main menu.

clear
gfx.drawImage file.loadImage("pics/title.png")

printMsg = function(s)
	text.row = 3
	text.color = "#EFAA2E"
	text.column = 34 - s.len/2
	print s
end function

printMsg "Loading..."

import "importUtil"
ensureImport "tileUtil"
ensureImport "lava"
ensureImport "kip"
ensureImport "enemies"
ensureImport "fireballs"
ensureImport "boss"
ensureImport "music"
ensureImport "smashables"

printMsg "Press gamepad button, spacebar, or Shift to play!"

while not kip.inputPressed("jump")
	yield
end while

// Fade out
display(0).mode = displayMode.solidColor
d = display(0)
for a in range(5, 255, 25)
	d.color = color.rgba(0, 0, 0, a)
	yield
end for

reset; run "main"