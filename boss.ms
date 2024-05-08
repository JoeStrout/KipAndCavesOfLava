// Manages the Boss (lava monster) character.

import "importUtil"
ensureImport "spriteControllers"
ensureImport "level"
ensureImport "qa"
ensureImport "mathUtil"

for _ in "IDLE RUNLEFT RUNRIGHT JUMPING FALLING CLIMBING".split
	locals[_] = spriteControllers[_]
end for
ATTACKING = "ATTACKING"
HURT = "HURT"
TAUNTING = "TAUNTING"
DYING = "DYING"

boss = new spriteControllers.Platformer
boss.x = 700; boss.y = 255
boss.footOffset = 130
boss.targetX = boss.x
boss.timeTillNextAction = 1
boss.phase = 0

boss.groundBelow = function(x, y)
	return level.groundBelowPoint(x, y)
end function

boss.faceX = function(x)
	if x > self.x then
		self.scale = self.normalScale
	else
		self.scale = self.flippedScale
	end if
end function

boss.runTowards = function(targetX)
	self.targetX = targetX
	if self.targetX > self.x then
		self.enterState RUNRIGHT
		self.targetSpeed = self.runSpeed
	else if self.targetX < self.x then
		self.enterState RUNLEFT
		self.targetSpeed = -self.runSpeed
	else
		self.enterState IDLE
		self.timeTillNextAction = 1  // try again a second later
	end if
end function

boss.checkInputs = function
	if self.state == TAUNTING then
		return
	else if self.state == IDLE then
		if self.timeTillNextAction > 0 then return
		// Pick an action!
		dx = kip.kip.x - self.x
		if rnd < [0.4, 0.6, 0.8][self.phase] and abs(dx) > 150 then
			// Throw a fireball!
			self.enterState ATTACKING
		else if rnd < [0.4, 0.75, 0.9][self.phase] then
			// Run to a random spot on the level.
			self.runTowards 256 + 256*floor(rnd*4)
		else 
			// Taunt
			self.enterState TAUNTING
		end if
	else if self.state == RUNLEFT then
		dx = self.targetX - self.x
		if dx > -10 then self.enterState IDLE
		if dx < -100 and self.vx < -200 and rnd < 0.02+0.02*self.phase then self.enterState JUMPING
	else if self.state == RUNRIGHT then
		dx = self.targetX - self.x
		if dx < -10 then self.enterState IDLE
		if dx > 100 and self.vx > 200 and rnd < 0.02+0.02*self.phase then self.enterState JUMPING
	end if
end function

boss.nextPhase = function
	if self.phase >= 2 then
		self.enterState DYING
	else
		self.phase += 1
		music.setPitch [1, 1.26, 1.5][self.phase]
	end if
end function

boss.enterState = function(newState)
	if newState == self.state then return
	super.enterState newState
	if newState == TAUNTING then
		self.play self.tauntAnim
		self.targetSpeed = 0
		sounds.playRoar self.x
	else if newState == IDLE then
		self.faceX kip.kip.x
		self.timeTillNextAction = round(1 + 4*rnd) / (1 + self.phase)
	else if newState == ATTACKING then
		self.faceX kip.kip.x
		self.play self.attackAnim
		self.lastFrame = 0
	else if newState == HURT then
		self.play self.hurtAnim
		score.addPoints 100 + 100 * self.phase
		sounds.playBossHurt self.x
		self.nextPhase
	else if newState == DYING then
		self.play self.dieAnim
		music.stop
		sounds.playBossDefeated
		score.addPoints 1000
		self.localBounds = null
		self.headCollider.localBounds = null
		// move to the back of the sprite list
		spriteControllers.disp.sprites.removeVal self
		spriteControllers.disp.sprites.insert 0, self
	end if
end function

boss.updateState = function(dt)
	super.updateState dt
	self.timeTillNextAction -= dt
	if self.state == TAUNTING and self.curAnim.curFrame == self.curAnim.frames.len-1 then
		self.enterState IDLE
	else if self.state == HURT and self.curAnim.curFrame == self.curAnim.frames.len-1 then
		self.enterState IDLE
	else if self.state == ATTACKING then
		if self.curAnim.curFrame == 4 and self.lastFrame == 3 then
			self.launchFireball
		else if self.curAnim.curFrame == 9 and self.lastFrame == 8 then
			if rnd > [0.3, 0.5, 0.7][self.phase] then self.enterState IDLE
		end if
		self.lastFrame = self.curAnim.curFrame
	else if self.state == DYING then
		if self.curAnim.curFrame == self.curAnim.frames.len - 1 and
				not sounds.snd.bossDefeated.isPlaying then
			wait 0.5
			gameOver "YOU WIN!", true
		end if
	end if
end function

boss.update = function(dt)
	super.update dt	
	self.headCollider.x = self.x + 20 * self.scale[0]
	self.headCollider.y = self.y + 40
	self.headCollider.rotation = -5 * self.scale[0]
	
	if self.state != HURT then
		// Check whether kip has hit us
		if self.headCollider.overlaps(kip.kip) then
			if kip.kip.vy < -100 then
				self.enterState HURT
				kip.kip.bounce
			else if kip.kip.invulnerableTime <= 0 then
				kip.kip.die
			end if
		else if self.overlaps(kip.kip) then
			kip.kip.die
		end if
	end if
end function

boss.applyFreefall = function(dt)
	// apply gravity
	// (with boost, as long as we're going up)
	self.vy = self.vy + (self.gravity + self.boost * self.inBoost) * dt
	// apply "fly" acceleration
	self.vx = mathUtil.moveTowards(self.vx, self.targetSpeed, self.flyAccel * dt)
	dx = self.vx * dt
	dy = self.vy * dt
	// check for hitting the ground or (ToDo) ceiling
	if self.vy < 0 then
		groundLevel = self.groundBelow(self.x, self.y - self.footOffset)
		if groundLevel > self.y - self.footOffset + dy then  // landed!
			self.x = self.x + dx * (groundLevel - self.y + self.footOffset) / dy
			self.y = groundLevel + self.footOffset
			self.runTowards self.targetX
			self.vy = 0
			return
		end if
	end if
	// apply velocity to position
	self.x = self.x + dx
	self.y = self.y + dy
end function

boss.launchFireball = function
	fb = new fireballs.Fireball
	fb.init
	fb.x = self.x + self.scale[0]*150
	fb.y = self.y + 80
	dx = kip.kip.x - fb.x
	dy = kip.kip.y - fb.y
	dist = sqrt(dx^2 + dy^2)
	speed = 400
	fb.vx = dx * speed / dist
	fb.vy = dy * speed / dist
	fb.rotation = atan(dy, dx) * 180/pi - 90
	fb.scale = 1.5
	sounds.playThrow fb.x
end function

setTilePosition = function(tileCol, tileRow)
	boss.x = tileCol*64 + 32
	boss.y = tileRow*64 + boss.footOffset
	boss.targetX = boss.x
end function

loadImages = function(imagePath, size=320)
	img = file.loadImage(imagePath)
	qa.assert img != null
	if size == null then size = img.height
	result = []
	y = img.height - size
	while y >= 0
		x = 0
		while x < img.width
			result.push img.getImage(x, y, size, size)
			x += size
		end while
		y -= size
	end while
	return result
end function

make = function
	newAnim = @spriteControllers.newAnimation
	spriteControllers.disp.sprites.push boss
	boss.attackAnim = newAnim(loadImages("pics/boss/boss_attack.png"))
	boss.idleAnim = newAnim(loadImages("pics/boss/boss_idle.png"))
	boss.runAnim = newAnim(loadImages("pics/boss/boss_run.png"))
	boss.jumpUpAnim = newAnim(loadImages("pics/boss/boss_jump.png"))
	boss.fallDownAnim = newAnim(loadImages("pics/boss/boss_fall.png"))
	boss.tauntAnim = newAnim(loadImages("pics/boss/boss_taunt.png"))
	boss.hurtAnim = newAnim(loadImages("pics/boss/boss_hurt.png"))
	boss.dieAnim = newAnim(loadImages("pics/boss/boss_die.png"))
	boss.dieAnim.loop = false
	for i in range(0,6)
		boss.hurtAnim.frames.push boss.idleAnim.frames[0]
		boss.hurtAnim.frames.push boss.idleAnim.frames[1]
		boss.hurtAnim.frames.push boss.idleAnim.frames[2]
		boss.hurtAnim.frames.push boss.idleAnim.frames[1]
	end for
	
	boss.curAnim = boss.tauntAnim
	boss.scale = boss.flippedScale
	boss.localBounds = new Bounds
	boss.localBounds.width = 150
	boss.localBounds.height = 160
	boss.localBounds.x = -20
	boss.localBounds.y = -50
	
	boss.headCollider = new Sprite
	boss.headCollider.localBounds = new Bounds
	spriteControllers.disp.sprites.push boss.headCollider
	return boss
end function

	
