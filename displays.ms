// This module sets up and manages all the display layers.

import "importUtil"
ensureImport "spriteControllers"
ensureImport "background"
ensureImport "lava"
ensureImport "tileUtil"
ensureImport "level"

setup = function
	clear
	
	// background in layer 7
	background.setup
	
	// stone in layer 6
	display(6).mode = displayMode.tile
	outer.stoneDisp = display(6)
	stoneDisp.clear 0
	tileUtil.loadFromFile "stone.dat", stoneDisp

	// sprites in layer 3
	display(3).mode = displayMode.sprite
	outer.spriteDisp = display(3)
	spriteDisp.clear
	spriteControllers.disp = spriteDisp
	fireballs.setup
	
	// text in layer 2
	display(2).mode = displayMode.text
	globals.text = display(2)
	text.clear

	// animated lava in layer 5	
	lava.setup
	
	// gameplay level in layer 4
	// (set up from main)
	
	// debug stuff in layer (as needed)
	if display(0).mode == displayMode.pixel then
		display(0).clear
	end if
	display(0).mode = displayMode.off
	
end function


if locals == globals then
	clear
	setup
	t0 = time
	while true
		t1 = time
		lava.update t1 - t0
		yield
		t0 = t1
	end while
end if
