// This manages the gameplay level: loading the tilemap,
// processing it to place sprites as needed, calculating
// the ground under any point, etc.

import "importUtil"
ensureImport "tileUtil"
ensureImport "lava"
ensureImport "kip"
ensureImport "enemies"
ensureImport "fireballs"
ensureImport "boss"
ensureImport "music"
ensureImport "smashables"

// Define special tile types
ladders = range(48, 51) + range(64, 68) + [84]

setup = function(levelPath = "level.dat")
	outer.name = levelPath - ".dat"
	display(4).mode = displayMode.tile
	outer.disp = display(4)
	disp.clear 0
	tileUtil.loadFromFile levelPath, disp
	disp.setCellTint range(0, disp.extent[0]), range(0, disp.extent[1]), color.white
	processLevel
	prepGroundMap
	
	if levelPath == "boss_level.dat" then
		// special considerations for the boss level
		camera.camBox.top = 580
		camera.camBox.bottom = 500
		camera.camBox.left = 200
		camera.camBox.right = 960 - camera.camBox.left
		music.startBossLevel
	else
		music.startMainLevel
	end if
end function

processLevel = function
	for y in range(0, disp.extent[1]-1)
		for x in range(0, disp.extent[0]-1)
			c = disp.cell(x, y)
			if c == 96 then
				smashables.Barrel.place x,y
			else if c == 102 then
				collectibles.Gem.place x, y
			else if c == 107 or c == 123 then
				disp.setCell x, y, null
				isTop = (c == 107)
				lava.set x, y, isTop
				lava.set x-1, y, isTop
				lava.set x+1, y, isTop
			else if c == 113 then
				collectibles.Coin.place x, y
			else if c == 114 then
				disp.setCell x, y, null
				kip.setTilePosition x, y
			else if c == 115 then
				disp.setCell x, y, null
				e = new enemies.Enemy
				e.init 0, x, y
			else if c == 116 then
				disp.setCell x, y, null
				e = new enemies.HelmetEnemy
				e.init 0, x, y
			else if c == 117 then
				disp.setCell x, y, null
				e = new enemies.SpikeyEnemy
				e.init 0, x, y
			else if c == 118 then
				disp.setCell x, y, null
				e = new enemies.FlyingEnemy
				e.init 0, x, y
			else if c == 119 then
				disp.setCell x, y, null
				lava.set x, y, true
				lava.set x-1, y, true
				lava.set x+1, y, true
				fb = new fireballs.PopupFireball
				fb.init x, y
			else if c == 120 then
				disp.setCell x, y, null
				boss.make
				boss.setTilePosition x, y			
			end if
		end for
	end for

end function

// functions that can define ground height in a cell:
_fullSolid = function(x)
	return 64
end function
_halfSolidLeft = function(x)
	if x < 32 then return 64 else return null
end function
_halfSolidRight = function(x)
	if x > 32 then return 64 else return null
end function
_fullSlopeUp = function(x)
	return x
end function
_fullSlopeDown = function(x)
	return 63 - x
end function
_halfSlopeUpBottom = function(x)
	return floor(x/2)
end function
_halfSlopeUpTop = function(x)
	return 32 + floor(x/2)
end function
_halfSlopeDownBottom = function(x)
	return floor((63-x)/2)
end function
_halfSlopeDownTop = function(x)
	return 32 + floor((63-x)/2)
end function

prepGroundMap = function
	outer.groundMap = {}  // key: tile number; function: ground func
	for i in range(0, 127)
		groundMap[i] = null
	end for
	// Fully solid blocks and flat platforms
	for col in range(0,3) + range(12,15)
		for row in range(1,4)
			groundMap[row*16+col] = @_fullSolid
		end for
	end for
	groundMap[smashables.SMASHABLE_TILE_IDX] = @_fullSolid
	// Slopes
	for row in range(0,2)
		groundMap[row*16+3] = @_halfSlopeUpBottom
		groundMap[row*16+4] = @_halfSlopeUpTop
		groundMap[row*16+7] = @_halfSlopeDownTop
		groundMap[row*16+8] = @_halfSlopeDownBottom
		groundMap[row*16+10] = @_fullSlopeUp
		groundMap[row*16+11] = @_fullSlopeDown		
	end for
	for row in range(1,2)
		groundMap[row*16+9] = @_fullSolid
		groundMap[row*16+5] = @_halfSolidLeft
		groundMap[row*16+6] = @_halfSolidRight
	end for
	// ToDo: rocks!
end function

groundBelowPoint = function(x, y)
	col = floor(x / 64)
	row = floor(y / 64)
	firstRow = true
	while true
		if row < 0 then return 0
		tile = disp.cell(col, row)
		f = null
		if tile != null then f = groundMap[tile]
		if @f then f = f(x % 64)
		if f then
			localGround = row*64 + f
		else
			localGround = null
		end if
		//print "row " + row + ": tile=" + tile + ", f=" + @f + ", localGround: " + localGround
		if localGround < y then return localGround
		row -= 1
	end while
end function

climbable = function(x, y, dir)
	col = floor(x / 64)
	row = floor(y / 64)
	return ladders.indexOf(disp.cell(col, row)) != null
end function

blocksWalking = function(x, y)
	// return whether the given pixel position is blocked from walking
	// (horizontal movement), i.e., there is a solid block there
	col = floor(x / 64)
	row = floor(y / 64)
	tile = disp.cell(col, row)
	if tile == smashables.SMASHABLE_TILE_IDX then return true
	tileRow = floor(tile / 16)
	tileCol = floor(tile % 16)
	if 1 <= tileRow <= 4 then return tileCol >= 12
	if tileRow == y then return tileCol < 4
	return false
end function
		
_lastMouseLine = null  // [x0, y0, x1, y1]
showGroundBelowMouse = function
	if display(0).mode != displayMode.pixel then
		display(0).mode = displayMode.pixel
		display(0).clear color.clear
	end if
	g = display(0)
	y = groundBelowPoint(mouse.x, mouse.y)
	if _lastMouseLine then
		g.line _lastMouseLine[0],  _lastMouseLine[1], 
		   _lastMouseLine[2],  _lastMouseLine[3], color.clear 
	end if
	g.line mouse.x, mouse.y, mouse.x, y, color.yellow
	outer._lastMouseLine = [mouse.x, mouse.y, mouse.x, y]
end function

checkGround = function
	while true
		showGroundBelowMouse
		yield
	end while
end function

if locals == globals then
	clear
	setup
	while true
		showGroundBelowMouse
		yield
	end while
end if
