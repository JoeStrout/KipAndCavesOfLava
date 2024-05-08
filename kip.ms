// This module controls Kip, the player avatar
// and hero of our adventure!

import "importUtil"
ensureImport "spriteControllers"
ensureImport "level"
ensureImport "mathUtil"

for _ in "IDLE RUNLEFT RUNRIGHT JUMPING FALLING CLIMBING".split
	locals[_] = spriteControllers[_]
end for
SPAWNING = ""

kip = new spriteControllers.Platformer
kip.x = 400; kip.y = 80
kip.localBounds = new Bounds
kip.localBounds.width = 55
kip.localBounds.height = 65
kip.localBounds.y = -14
kip.footOffset = 48
kip.needBounce = false	// hacky way to get a bounce on the next update
kip.bounceTimeLeft = 0
kip.invulnerableTime = 0
kip.lastState = ""
kip.lastFrame = -1

kip.groundBelow = function(x, y)
	return level.groundBelowPoint(x, y)
end function

setTilePosition = function(tileCol, tileRow)
	kip.x = tileCol*64 + 32
	kip.y = tileRow*64 + 40
	kip.rotation = 0
	kip.enterState SPAWNING
	kip.spawnPoint = [tileCol, tileRow]
	spriteControllers.disp.sprites.removeVal kip
	spriteControllers.disp.sprites.push kip
end function

setup = function
	// Set up our player character, "Kip"
	newAnim = @spriteControllers.newAnimation
	spriteControllers.disp.sprites.push kip
	kip.standImage = file.loadImage("/sys/pics/KP/KP-stand.png")
	kip.waveImage = file.loadImage("/sys/pics/KP/KP-wave.png")
	kip.idleAnim = newAnim(kip.standImage)
	kip.runAnim = newAnim([
	   file.loadImage("/sys/pics/KP/KP-run1.png"),
	   file.loadImage("/sys/pics/KP/KP-run2.png")], 10)
	kip.jumpUpAnim = newAnim(file.loadImage("/sys/pics/KP/KP-jump.png"))
	kip.fallDownAnim = kip.jumpUpAnim
	kip.climbAnim = newAnim([
	   file.loadImage("/sys/pics/KP/KP-climb1.png"),
	   file.loadImage("/sys/pics/KP/KP-climb2.png")], 10)
	kip.curAnim = kip.idleAnim
	kip.enterState SPAWNING
end function

kip.die = function
//	debugBounds.update; exit
	sounds.playDeath self.x
	self.image = file.loadImage("/sys/pics/KP/KP-fallen.png")
	spriteControllers.disp.sprites.removeVal self
	spriteControllers.disp.sprites.push self
	vy = 40
	startY = self.y
	while self.y >= startY
		self.y += vy
		vy -= 2
		self.rotation += 25
		yield
	end while
	
	while sounds.snd.death.isPlaying; yield; end while
	wait 0.25
	
	if score.lives == 0 then
		gameOver "out of lives"
	else
		score.spendLife
		setTilePosition self.spawnPoint[0], self.spawnPoint[1]
	end if
end function

inputPressed = function(keyOrValue)
	if keyOrValue == "left" then
		return key.axis("Horizontal", false) < 0
	else if keyOrValue == "right" then
		return key.axis("Horizontal", false) > 0
	else if keyOrValue == "down" then
		return key.axis("Vertical", false) < 0
	else if keyOrValue == "up" then
		return key.axis("Vertical", false) > 0
	else if keyOrValue == "space" or keyOrValue == "jump" then
		return key.pressed("space") or key.pressed("left shift") or 
		  key.pressed("right shift") or key.pressed("joystick button 0") or
		  key.pressed("joystick button 1")
	end if
end function

nullInput = function(ignored)
	return false
end function

kip.update = function(dt)
	if self.state == SPAWNING then
		self.scale = [1, mathUtil.clamp(self.scale[1] + dt, 0, 1)]
		self.y += 48 * dt
		if self.scale[1] == 1 then self.enterState IDLE
		return
	end if
	
	// Note: we have lots of NPCs that are also Platformers.
	// But the Platformer code uses a module-level inputPressed
	// function.  That's a flaw.  We work around it by assigning
	// our real input function when updating kip, and then 
	// assigning a dummy function that always returns false for
	// everybody else.
	spriteControllers.inputPressed = @inputPressed
	super.update dt
	spriteControllers.inputPressed = @nullInput

	self.checkWalls
	self.checkEnemies
	if lava.isLava(self.x, self.y - self.footOffset) then self.die
	tile = level.disp.cell(self.x/64, self.y/64)
	if tile == 92 then self.die // (spikes)
	if tile == 105 then  // checkpoint
		level.disp.setCell self.x/64, self.y/64, 106
		self.spawnPoint = [floor(self.x/64)+1, floor(self.y/64)]
	end if
	if self.needBounce then self.bounce
	if self.bounceTimeLeft > 0 then
		self.bounceTimeLeft -= dt
		if self.bounceTimeLeft < 0 then self.bounceTimeLeft = 0
	end if
	if self.invulnerableTime > 0 then
		self.invulnerableTime -= dt
		if sin(self.invulnerableTime*10) > 0 then a = 255 else a = 100
		if self.invulnerableTime <= 0 then
			a = 255
			self.invulnerableTime = 0
		end if
		self.tint = color.rgba(255, 255, 255, a)
	end if
	
	if self.state != self.lastState then
		self.lastState = self.state
		self.lastFrame = self.curAnim.curFrame
		if self.state == "JUMPING" then
			sounds.playJump self.x
		end if
	else if self.curAnim.curFrame != self.lastFrame then
		self.lastState = self.state
		self.lastFrame = self.curAnim.curFrame
		if self.state == RUNLEFT or self.state == RUNRIGHT then
			sounds.playFootstep self.x
		end if
	end if
end function

kip.canClimb = function(dir)
	if not level.climbable(self.x, self.y - self.footOffset * (1 - 0.1*dir), 
	     dir) then
		// special case: we can't climb, but maybe we're standing in
		// front of a door and pushing up?
		c = level.disp.cell(self.x / 64, self.y / 64)
		if dir > 0 and level.name == "level" and (c == 124 or c == 125) then
			startNextLevel
			return
		end if
		return false
	end if
	
	// since we can climb, we probably are about to do so...
	// so let's center ourselves horizontally on the ladder
	self.x = (floor(self.x / 64) + 0.5) * 64
	return true
end function

kip.checkWalls = function
	if self.vx >= 0 and level.blocksWalking(self.x + 28, self.y) then
		self.x = floor((self.x + 28)/64) * 64 - 28
	end if
	if self.vx <= 0 and level.blocksWalking(self.x - 28, self.y) then
		self.x = ceil((self.x - 28)/64) * 64 + 28
	end if
end function

kip.checkInputs = function
	if self.state == SPAWNING then return
	super.checkInputs
	if self.bounceTimeLeft and spriteControllers.inputPressed(self.jumpInput) then
		self.enterState JUMPING
		self.vy = self.jumpSpeed * (1 + self.bounceTimeLeft/0.3)
		self.bounceTimeLeft = 0
	end if
	if spriteControllers.inputPressed(self.upInput) then
		self.idleAnim.frames[0] = self.waveImage
	else
		self.idleAnim.frames[0] = self.standImage
	end if
end function

kip.enterState = function(newState)
	if self.state == FALLING and newState == IDLE and smashables.check(self) then
		self.needBounce = true
	else
		super.enterState newState
	end if
	if newState == SPAWNING then
		kip.scale = [1,0]
		kip.y -= 40
		kip.image = kip.idleAnim.frames[0]
		kip.invulnerableTime = 3
	end if
end function

kip.bounce = function
	self.enterState JUMPING
	self.vy = 600  // just a little bounce
	self.bounceTimeLeft = 0.2
	self.needBounce = false
end function

kip.checkEnemies = function
	for e in enemies.Enemy.instances
		if not e.overlaps(self) then continue
		// We've hit an enemy!  What to do?
		if self.y - self.footOffset > e.y + self.vy*.01 and self.vy < -100 then
			// Bounced on him!
			e.squash
			self.bounce
		else if self.invulnerableTime <= 0 then
			// didn't jump on him, so, we die
			globals.e = e; globals.k = self
			self.die
		end if
	end for
end function