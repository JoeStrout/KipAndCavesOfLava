// Manages the fireballs that mostly pop up out of the lava.
// (Maybe boss-thrown fireballs too; not sure yet.)

import "importUtil"
ensureImport "spriteControllers"
ensureImport "mathUtil"
ensureImport "listUtil"

setup = function
	spriteSheet = file.loadImage("pics/fireball.png")
	outer.frames = []
	for i in range(0, 4)
		frames.push spriteSheet.getImage(i*64, 0, 64, 64)
	end for
end function


Fireball = new spriteControllers.Animated
Fireball.localBounds = new Bounds
Fireball.localBounds.width = 28
Fireball.localBounds.height = 40
Fireball.vx = 0
Fireball.vy = 0

Fireball.init = function(tileCol=5, tileRow=1)
	self.x = tileCol * 64 + 32
	self.y = tileRow * 64 + 32
	spriteControllers.disp.sprites.push self
	self.curAnim = spriteControllers.newAnimation(frames, 10)
end function

Fireball.update = function(dt=0.1)
	super.update dt
	self.x += self.vx * dt
	self.y += self.vy * dt
	if self.tint != color.clear and self.overlaps(kip.kip) and
	  kip.kip.invulnerableTime <= 0 then kip.kip.die			
end function

PopupFireball = new Fireball
PopupFireball.timeToNextLaunch = 0
PopupFireball.launched = false

PopupFireball.init = function(tileCol=5, tileRow=1)
	super.init tileCol, tileRow
	self.timeToNextLaunch = (tileCol * 101) % 7
	self.startY = self.y
	self.tint = color.clear
end function

PopupFireball.update = function(dt=0.1)
	super.update dt
	self.timeToNextLaunch -= dt
	if self.launched then
		self.vy -= 6000 * dt
		self.rotation = 180 * (self.vy < 0)
		if self.y < self.startY then
			self.launched = false
			self.tint = color.clear
			sounds.playSplort self.x
		end if
	else if self.timeToNextLaunch < 0 then
		self.timeToNextLaunch += 4
		self.y = self.startY
		self.vy = 2000
		self.rotation = 0
		self.tint = color.white
		self.launched = true
		sounds.playSplurt self.x
	end if
end function

if locals == globals then
	clear
	setup
	fb = new Fireball
	fb.init
	print "Launching in " + fb.timeToNextLaunch

	t0 = time
	while true
		t1 = time
		fb.update t1 - t0
		text.row = 25; print fb.contains(mouse)
		yield
		t0 = t1
	end while
end if
