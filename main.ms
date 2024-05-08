// Main program.

import "importUtil"

ensureImport "displays"
ensureImport "kip"
ensureImport "camera"
ensureImport "boss"
ensureImport "collectibles"
ensureImport "smashables"
ensureImport "debugBounds"
ensureImport "score"
ensureImport "sounds"
ensureImport "bmfFonts"

displays.setup
kip.setup
fireballs.setup
collectibles.setup
smashables.setup
score.reset
level.setup // "boss_level.dat"
camera.reset
camera.update kip.kip.x, kip.kip.y

_startNext = false
startNextLevel = function
	// This gets called from deep in the call stack, which causes grief
	// as it unwinds.  So let's just set a flag, and really start the
	// next level later, from the main loop.
	outer._startNext = true
end function

reallyStartNextLevel = function
	outer._startNext = false
	
	score.timeBonus += 10 * floor(music.timeLeft)
	
	// Fade out
	display(0).mode = displayMode.solidColor
	d = display(0)
	for a in range(5, 255, 25)
		d.color = color.rgba(0, 0, 0, a)
		yield
	end for
	
	// Clear data
	enemies.Enemy.destroyAll
	displays.spriteDisp.sprites = [kip.kip]
	lava.clearAll
	collectibles.clear
	smashables.clear
	
	// Set up new level
	level.setup "boss_level.dat"
	camera.reset
	camera.update kip.kip.x, kip.kip.y
	
	// Fade back in
	for a in range(255, 0, -25)
		d.color = color.rgba(0, 0, 0, a)
		yield
	end for
	display(0).mode = displayMode.off
end function

gameOver = function(reason, won=false)
	music.update true  // (force redraw)
	music.stop
	if won then
		score.timeBonus += 10 * floor(music.timeLeft)
	end if
	
	f = bmfFonts.Font.load("/sys/fonts/ArialBlack22.bmf")
	display(0).mode = displayMode.pixel
	globals.gfx = display(0)
	gfx.clear color.clear
	f.printCentered "GAME OVER", 480, 500, 2, color.yellow
	
	f.printCentered reason, 480, 450, 1, color.yellow
	
	f.printRight "BASE SCORE:", 440, 350, 1, "#CCCCCC"
	f.print ("00000" + score.points)[-5:], 520, 350, 1, "#CCCCCC"
	
	f.printRight "TIME BONUS:", 440, 310, 1, "#CCCCCC"
	if score.timeBonus > 0 then
		f.print ("00000" + score.timeBonus)[-5:], 520, 310, 1, "#CCCCCC"
	else
		f.print "N/A", 520, 310, 1, "#CCCCCC"	
	end if
	
	total = score.points + score.timeBonus
	f.printRight "TOTAL SCORE:", 440, 250, 1, color.yellow
	f.print ("00000" + total)[-5:], 520, 250, 1, color.yellow
	
	if total > 4000 then
		title = "GAMING GOD"
	else if total > 3000 then
		title = "DEMIGOD"
	else if total > 2500 then
		title = "HERO"
	else if total > 2000 then
		title = "ADVENTURER"
	else if total > 1000 then
		title = "SPELUNKER"
	else if total > 500 then
		title = "EXPLORER"
	else
		title = "TOURIST"
	end if
	f.printRight "TITLE:", 440, 210, 1, color.white
	f.print title, 520, 210, 1, color.white
	
	sounds.playGameOver
	while sounds.snd.gameOver.isPlaying; wait; end while
	
	while kip.inputPressed("jump"); yield; end while
	f.printCentered "(Press Jump to continue.)", 480, 20, 1, color.gray
	while not kip.inputPressed("jump"); yield; end while
	
	gfx.clear color.black
	reset
	run "title"
end function	

// Fade back in
display(0).mode = displayMode.solidColor
d = display(0)
for a in range(255, 0, -25)
	d.color = color.rgba(0, 0, 0, a)
	yield
end for
display(0).mode = displayMode.off

// Main loop
t0 = time
while true
	t1 = time
	dt = t1 - t0
	t0 = t1
	
	lava.update dt
	collectibles.update dt
	smashables.update dt
	spriteControllers.updateSprites dt
	camera.update kip.kip.x + kip.kip.vx/4, kip.kip.y
	music.update
	if music.timeLeft <= 0 then gameOver "Time up!"
	//debugBounds.update
	
	if _startNext then reallyStartNextLevel
	
	yield
end while