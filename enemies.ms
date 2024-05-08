// This module manages our standard "mushroom" type enemies:
// Shroom, Helmet Shroom, Spike, and Flapper.  These differ
// in their movement pattern and in what happens when you
// jump on them.

// Each of them is actually composed of two sprites: a faceless
// main sprite, and then a face sprite.  This is so we can change
// the face expression or eye direction.

import "importUtil"
ensureImport "spriteControllers"
ensureImport "mathUtil"
ensureImport "listUtil"
ensureImport "score"

for _ in "IDLE RUNLEFT RUNRIGHT JUMPING FALLING CLIMBING".split
	locals[_] = spriteControllers[_]
end for
WAITING = "WAITING"
SQUASHING = "SQUASHING"
POPPING = "POPPING"

spriteSheet = file.loadImage("pics/Enemies_Faceless.png")

sheetCell = function(column, row)
	return spriteSheet.getImage(column*64, 192-row*64, 64, 64)
end function

faceImages = {}
faceImages.lookLeft = sheetCell(4, 2)
faceImages.lookRight = sheetCell(5, 2)
faceImages.lookDownLeft = sheetCell(4, 3)
faceImages.lookDownRight = sheetCell(5, 3)
faceImages.uhOh = sheetCell(4, 1)
faceImages.dead = sheetCell(5,1)

//----------------------------------------------------------------------
// Base class for all the shroom enemies.
Enemy = new spriteControllers.Platformer
Enemy.face = new Sprite
Enemy.face.image = sheetCell(4, 2)
Enemy.flippedScale = Enemy.normalScale  // no flipping!
Enemy.runSpeed = 100
Enemy.gravity = -2000
Enemy.instances = []
Enemy.facingLeft = true
Enemy.localBounds = new Bounds
Enemy.localBounds.width = 60
Enemy.localBounds.height = 50
Enemy.localBounds.y = 5
Enemy.pointValue = 25

Enemy.init = function(spriteSheetColumn=0, tileCol=5, tileRow=5)
	self.runAnim = spriteControllers.newAnimation(
			[sheetCell(spriteSheetColumn, 0),
			sheetCell(spriteSheetColumn, 1)], 3)
	self.idleAnim = self.runAnim
	self.jumpUpAnim = self.runAnim
	self.fallDownAnim = self.runAnim
	self.setTilePosition tileCol, tileRow
	self.face = new Enemy.face
	self.face.y = -1000
	spriteControllers.disp.sprites.push self
	spriteControllers.disp.sprites.push self.face
	self.curAnim = self.idleAnim
	self.state = WAITING
	self.footOffset = self.idleAnim.frames[0].height/2
	Enemy.instances.push self
end function

Enemy.setTilePosition = function(tileCol, tileRow)
	self.x = tileCol*64 + 32
	self.y = tileRow*64 + 32
	self.face.x = self.x
	self.face.y = self.y
end function

Enemy.destroy = function
	spriteControllers.disp.sprites.removeVal self.face
	spriteControllers.disp.sprites.removeVal self
	Enemy.instances.removeVal self
end function

Enemy.destroyAll = function
	for i in range(self.instances.len - 1, 0, -1)
		self.instances[i].destroy
	end for
end function

Enemy.groundBelow = function(x, y)
	return level.groundBelowPoint(x, y)
end function

Enemy.update = function(dt=0.1)
	if self.state == WAITING then
		if self.x - spriteControllers.disp.scrollX < 990 then
			self.enterState IDLE
		end if
		return
	end if
	super.update dt
	self.face.x = self.x - 2 * self.facingLeft
	self.face.y = self.y
	if self.state == SQUASHING or self.state == POPPING then return
	kip = kip.kip
	if self.y > kip.y + 100 then
		if self.x > kip.x then
			self.face.image = faceImages.lookDownLeft
		else
			self.face.image = faceImages.lookDownRight
		end if
	else
		if self.x > kip.x then
			self.face.image = faceImages.lookLeft
		else
			self.face.image = faceImages.lookRight
		end if
	end if
end function

Enemy.updateState = function(dt)
	if self.state == SQUASHING then
		t = (time - self.stateStartTime) / 0.15
		self.scale = [1, mathUtil.lerp(1, 0.5, t)]
		self.face.scale = self.scale
		self.y = mathUtil.lerp(self.startY, self.startY - 16, t)
		if t > 1 then self.destroy
	else if self.state == POPPING then
		self.scale += dt * 2
		self.face.scale = self.scale
		if self.scale < 1.25 then a = 255 else a = 255 * 4 * (1.5 - self.scale)
		self.tint = color.rgba(255, a, a, a)		
		if a < 0 then self.destroy
	else
		super.updateState dt
		if lava.isLava(self.x, self.y - self.footOffset) or
		  level.disp.cell(self.x/64, (self.y - self.footOffset)/64) == 92 then
			self.enterState POPPING
		end if
	end if
end function

Enemy.enterState = function(newState)
	if newState == self.state then return
	super.enterState newState
	if newState == SQUASHING then
		self.startY = self.y
		self.face.image = faceImages.dead
		self.localBounds = null  // (no more collisions for you!)
		score.addPoints self.pointValue
		sounds.playSquishEnemy self.x
	else if newState == POPPING then
		self.face.image = faceImages.dead
		self.scale = 1.3
		self.localBounds = null  // (no more collisions for you!)
		sounds.playPopEnemy self.x
	end if
end function

Enemy.checkInputs = function
	// simple "AI" code goes here!
	if self.state == SQUASHING or self.state == WAITING or self.state == POPPING then
		return
	end if
	if self.facingLeft then dx = -1 else dx = 1
	if level.blocksWalking(self.x + 32*dx, self.y) then
		self.facingLeft = not self.facingLeft
	end if
	if self.facingLeft then self.enterState RUNLEFT else self.enterState RUNRIGHT
	self.checkForGround
end function

Enemy.squash = function
	self.enterState SQUASHING
end function

//----------------------------------------------------------------------
// Helmet enemies: don't squash (much) when jumped on.
HelmetEnemy = new Enemy
HelmetEnemy.init = function(spriteSheetColumn=0, tileCol=5, tileRow=5)
	super.init 1, tileCol, tileRow
	globals.foo = self
	self.cachedBounds = self.localBounds
end function

HelmetEnemy.updateState = function(dt)
	if self.state == SQUASHING then
		t = (time - self.stateStartTime) / 0.15		
		if t > 0.5 then st = 1 - t else st = t
		self.scale = [1, mathUtil.lerp(1, 0.5, st)]
		self.face.scale = self.scale
		self.y = mathUtil.lerp(self.startY, self.startY - 16, st)
		if t > 1 then self.enterState IDLE
	else
		super.updateState dt
	end if
end function

HelmetEnemy.exitState = function
	if self.state == SQUASHING then
		self.localBounds = self.cachedBounds
	end if
end function


//----------------------------------------------------------------------
// Spikey enemies: lethal to jump on
SpikeyEnemy = new Enemy
SpikeyEnemy.init = function(spriteSheetColumn=0, tileCol=5, tileRow=5)
	super.init 2, tileCol, tileRow
end function

SpikeyEnemy.squash = function
	kip.kip.die
end function

//----------------------------------------------------------------------
// Flying enemies: ...they fly.  Duh.
FlyingEnemy = new Enemy
FlyingEnemy.pointValue = 75
FlyingEnemy.init = function(spriteSheetColumn=0, tileCol=5, tileRow=5)
	super.init 3, tileCol, tileRow
end function

FlyingEnemy.gravity = -200
FlyingEnemy.jumpSpeed = 250

FlyingEnemy.checkInputs = function
	// simple "AI" code goes here!
	if self.state == SQUASHING then return
	if self.facingLeft then dx = -1 else dx = 1
	if level.blocksWalking(self.x + 32*dx, self.y) then
		self.facingLeft = not self.facingLeft
		self.targetSpeed = 200 * ((not self.facingLeft) - 0.5)
	end if
	if self.state == IDLE or self.state == RUNLEFT or self.state == RUNRIGHT then
		self.enterState JUMPING
		self.targetSpeed = 200 * ((not self.facingLeft) - 0.5)
	else
		self.checkForGround
	end if
end function


//----------------------------------------------------------------------
if locals == globals then
	clear
	e = new Enemy
	e.init
end if
