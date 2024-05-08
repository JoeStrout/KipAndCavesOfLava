// This module manages items you can collect, like coins and gems.

import "importUtil"
ensureImport "spriteControllers"
ensureImport "mathUtil"
ensureImport "listUtil"
ensureImport "score"

// Define a special tile index that is invisible, but means
// "there is a collectible here"
COLLECTIBLE_TILE_IDX = 1

//----------------------------------------------------------------------
Collectible = new Sprite
Collectible.pointValue = 10
Collectible.instances = []

Collectible.place = function(tileX, tileY, instance)
	instance.x = tileX * 64 + 32
	instance.y = tileY * 64 + 32
	instance.tileX = tileX
	instance.tileY = tileY
	spriteControllers.disp.sprites.push instance
	Collectible.instances.push instance
	level.disp.setCell tileX, tileY, COLLECTIBLE_TILE_IDX
end function

Collectible.destroy = function
	Collectible.instances.removeVal self
	spriteControllers.disp.sprites.removeVal self
end function

Collectible.updateAll = function(dt = 0.1)
	kipRow = floor(kip.kip.y/64)
	kipCol = floor(kip.kip.x/64)
	if level.disp.cell(kipCol, kipRow) == COLLECTIBLE_TILE_IDX then
		Collectible.collectAt kipCol, kipRow
	end if
end function

Collectible.collectAt = function(tileX, tileY)
	for i in Collectible.instances.indexes
		c = Collectible.instances[i]
		if c.tileX == tileX and c.tileY == tileY then
			c.collect
			level.disp.setCell tileX, tileY, 0
			break
		end if
	end for
end function

Collectible.collect = function
	score.addPoints self.pointValue
	self.destroy
end function

//----------------------------------------------------------------------
Coin = new Collectible
Coin.frames = []
Coin.curFrame = 0
Coin.timeTillNextFrame = 0
Coin.instances = []

Coin.place = function(tileX, tileY)
	coin = new Coin
	super.place tileX, tileY, coin
	Coin.instances.push coin
end function

Coin.destroy = function
	super.destroy
	Coin.instances.removeVal self
end function

Coin.updateAll = function(dt = 0.1)
	Coin.timeTillNextFrame -= dt
	if Coin.timeTillNextFrame < 0 then
		Coin.timeTillNextFrame = 0.08
		Coin.curFrame = (Coin.curFrame + 1) % Coin.frames.len
		Coin.image = Coin.frames[Coin.curFrame]
		// Sadly, a Sprite can't just inherit its image from the
		// base class; the actual display image only updates when
		// you assign to the .image property on the instance.
		// So we must:
		for item in Coin.instances
			item.image = Coin.image
		end for
	end if
end function

Coin.collect = function
	// ToDo: fancy little collection animation (and sound FX)
	score.gotCoin self.pointValue
	sounds.playCoin self.x
	self.destroy
end function

//----------------------------------------------------------------------
Gem = new Collectible
Gem.totalTime = 0
Gem.image = file.loadImage("pics/gem_purple.png")
Gem.instances = []
Gem.pointValue = 100

Gem.place = function(tileX, tileY)
	gem = new Gem
	super.place tileX, tileY, gem
	gem.image = Gem.image
	gem.baseY = gem.y
	Gem.instances.push gem
end function

Gem.destroy = function
	super.destroy
	Gem.instances.removeVal self
end function

Gem.updateAll = function(dt = 0.1)
	Gem.totalTime += dt
	dy = abs(sin(Gem.totalTime * 4)) * 20
	for gem in Gem.instances
		gem.y = gem.baseY + dy
	end for
end function

Gem.collect = function
	// ToDo: fancy little collection animation (and sound FX)
	score.gotGem self.pointValue
	sounds.playGem self.x
	self.destroy
end function

//----------------------------------------------------------------------

setup = function
	spriteSheet = file.loadImage("pics/coin.png")
	Coin.frames = []
	for i in range(0, 3)
		Coin.frames.push spriteSheet.getImage(i*42, 0, 42, 42)
	end for
	Coin.image = Coin.frames[0]
end function

clear = function
	for i in range(Gem.instances.len-1, 0, -1); Gem.instances[i].destroy; end for
	for i in range(Coin.instances.len-1, 0, -1); Coin.instances[i].destroy; end for
	for i in range(Collectible.instances.len-1, 0, -1); Collectible.instances[i].destroy; end for
end function

update = function(dt=0.1)
	Collectible.updateAll dt
	Coin.updateAll dt
	Gem.updateAll dt
end function