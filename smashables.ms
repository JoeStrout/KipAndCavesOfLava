// Manages objects on the level that can be smashed, by
// hitting them from above (or below?) with sufficient velocity.

import "importUtil"
ensureImport "spriteControllers"
ensureImport "mathUtil"
ensureImport "listUtil"
ensureImport "mapUtil"
ensureImport "score"
ensureImport "collectibles"

// Define a special tile index that is invisible, but means
// "there is a smashable here"
SMASHABLE_TILE_IDX = 2

loadParts = function(path)
	img = file.loadImage(path)
	parts = [] // top-right, top-left, bottom-left, bottom-right
	w = img.width/2
	h = img.height/2
	parts.push img.getImage(w, h, w, h)
	parts.push img.getImage(0, h, w, h)
	parts.push img.getImage(0, 0, w, h)
	parts.push img.getImage(w, 0, w, h)
	return parts
end function

//----------------------------------------------------------------------
Smashable = new Sprite
Smashable.pointValue = 50
Smashable.parts = null	// top-right, top-left, bottom-left, bottom-right

Smashable.byPos = {}  // key: [tileX,tileY]; value: Smashable

Smashable.place = function(tileX, tileY, instance)
	instance.x = tileX * 64 + 32
	instance.y = tileY * 64 + 32
	instance.tileX = tileX
	instance.tileY = tileY
	spriteControllers.disp.sprites.push instance
	Smashable.byPos[ [tileX,tileY] ] = instance
	level.disp.setCell tileX, tileY, SMASHABLE_TILE_IDX
end function

Smashable.smash = function
	level.disp.setCell self.tileX, self.tileY, 0
	Smashable.byPos.remove([self.tileX, self.tileY])
	spriteControllers.disp.sprites.removeVal self
	v = 200
	Part.make self.parts[0], self.x+20, self.y+20, v/4, v*2
	Part.make self.parts[1], self.x-20, self.y+20, -v/4, v*2
	Part.make self.parts[2], self.x-20, self.y-20, -v, v
	Part.make self.parts[3], self.x+20, self.y-20, v, v
	
	score.addPoints self.pointValue
	sounds.playBreakCrate self.x
	
	collectibles.Gem.place self.tileX, self.tileY
end function

Smashable.checkAll = function(kip)
	// first, make sure kip is moving fast enough to smash
	if kip.vy > -1800 then return
	// then find what he would hit
	tileX0 = floor((kip.x - 20) / 64)
	tileX1 = floor((kip.x + 20) / 64)
	tileY = floor((kip.y - kip.footOffset - 20) / 64)
	item = Smashable.byPos.get([tileX0, tileY])
	if item then item.smash
	item = Smashable.byPos.get([tileX1, tileY])
	if item then item.smash	
end function

//----------------------------------------------------------------------
Part = new Sprite
Part.vx = 0
Part.vy = 100
Part.age = 0
Part.instances = []

Part.make = function(image, x, y, vx, vy)
	part = new Part
	part.image = image
	part.x = x
	part.y = y
	part.vx = vx
	part.vy = vy
	Part.instances.push part
	spriteControllers.disp.sprites.push part
end function

Part.update = function(dt = 0.1)
	self.x += self.vx * dt
	self.y += self.vy * dt
	self.vy -= 1000 * dt
	self.age += dt
	if self.age > 1 then
		spriteControllers.disp.sprites.removeVal self
		Part.instances.removeVal self
	else if self.age > 0.75 then
		a = 255 * (1 - self.age) * 4
		self.tint = color.rgba(255, 255, 255, a)
	end if
end function

Part.updateAll = function(dt = 0.1)
	for i in range(Part.instances.len-1, 0, -1)
		Part.instances[i].update dt
	end for
end function

//----------------------------------------------------------------------
Barrel = new Smashable
Barrel.image = file.loadImage("pics/barrel.png")
Barrel.parts = loadParts("pics/barrel_parts.png")

Barrel.place = function(tileX, tileY)
	inst = new Barrel
	super.place tileX, tileY, inst
	return inst
end function

//----------------------------------------------------------------------

setup = function
	
end function

clear = function
	for item in Smashable.byPos.values
		spriteControllers.disp.sprites.removeVal item
	end for
	Smashable.byPos = {}
	for item in Part.instances[:]
		spriteControllers.disp.sprites.removeVal item
	end for
	Part.instances = []	
end function

update = function(dt=0.1)
//	Smash.checkAll dt
	Part.updateAll dt
end function

check = function(kip)
	prevPartCount = Part.instances.len
	Smashable.checkAll kip
	return Part.instances.len > prevPartCount
end function

if locals == globals then
	level = {}
	level.disp = {}
	level.disp.setCell = function(x,y,id); end function

	clear
	b = Barrel.place(8, 2)
	b.smash
	while Part.instances
		Part.updateAll 1/60
		yield
	end while
end if
