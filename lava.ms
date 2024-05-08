// This module handles animated lava tiles.  These go in 
// their own layer, so that they can sit behind rocks
// which only partially fill their tile.  And also because
// the lava tileset is nothing but lava!

setup = function(columns=150, rows=15)
	outer.lavaImages = []
	i = 0
	while true
		p = file.loadImage("pics/lava/lava_" + ("00"+i)[-2:] + ".png")
		if not p then break
		lavaImages.push p
		i += 1
	end while
	
	display(5).mode = displayMode.tile
	outer.disp = display(5)
	disp.cellSize = 64
	disp.tileSet = lavaImages[0]
	disp.tileSetTileSize = 64
	disp.extent = [columns, rows]
	disp.clear null
end function

set = function(col, row, isTop=true)
	disp.setCell col, row, (col*13) % 4 + 4*(not isTop)
end function

clearAll = function
	disp.clear null
end function

addLava = function(col, row, cols=1, rows=1)
	maxCol = col + cols - 1
	maxRow = row + rows - 1
	for c in range(col, maxCol)
		for r in range(row, maxRow)
			set c, r, r == maxRow
		end for
	end for
end function

isLava = function(x, y)
	c = disp.cell(x / 64, y / 64)
	if c == null then return false
	if c > 3 then return true
	return y % 64 < 32
end function

curFrame = 0
timeTillNextFrame = 0.1
update = function(dt=0.1)
	outer.timeTillNextFrame -= dt
	if timeTillNextFrame < 0 then
		outer.curFrame = (curFrame + 1) % lavaImages.len
		disp.tileSet = lavaImages[curFrame]
		outer.timeTillNextFrame += 0.1
	end if
end function

if locals == globals then
	clear
	gfx.clear color.clear
	setup
	addLava 3, 0, 6, 3
	
	t0 = time
	while true
		t1 = time
		update t1 - t0
		yield
		t0 = t1
	end while
end if
