import "importUtil"
ensureImport "stringUtil"
ensureImport "displays"
ensureImport "mathUtil"

snd = {}

for item in file.children("sounds")
	if item.endsWith(".wav") then
		s = file.loadSound("sounds/" + item)
		if s then snd[item - ".wav"] = s
	end if
end for

play = function(sound, volume=1, worldX = null, pitch=1)
	if worldX == null then
		sound.play
	else
		screenX = worldX - displays.spriteDisp.scrollX
		if screenX < -100 or screenX > 1060 then return
		if screenX < 0 then
			volume *= (screenX + 100) * 0.01
		else if screenX > 960 then
			volume *= (1060 - screenX) * 0.01
		end if
		pan = mathUtil.clamp((screenX - 480) / 480, -1, 1)
		sound.play volume, pan, pitch
	end if
end function

playFootstep = function(worldX)
	if rnd < 0.5 then s = snd.stepA else s = snd.stepB
	play s, 0.2 + 0.4*rnd, worldX
end function

playJump = function(worldX)
	play snd.jump, 1, worldX
end function

playLanding = function(worldX)
	play snd.landing, 1, worldX
end function

playCoin = function(worldX)
	play snd.coin, 1, worldX, 0.9+0.2*rnd
end function

playGem = function(worldX)
	play snd.gem, 1, worldX
end function

playGameOver = function
	play snd.gameOver
end function

playSquishEnemy = function(worldX)
	play snd.squish, 1, worldX, 0.9+0.2*rnd
end function

playPopEnemy = function(worldX)
	play snd.pop, 1, worldX, 0.9+0.2*rnd
end function

playSplurt = function(worldX)
	play snd.splurt, 1, worldX, 0.9+0.2*rnd
end function

playSplort = function(worldX)
	play snd.splort, 1, worldX, 0.9+0.2*rnd
end function

playBreakCrate = function(worldX)
	play snd.breakCrate, 1, worldX
end function

playDeath = function(worldX)
	play snd.death, 1, worldX
end function

playThrow = function(worldX)
	play snd.throw, 1, worldX, 0.9+0.2*rnd
end function

playRoar = function(worldX)
	play snd.roar, 1, worldX, 0.8+0.4*rnd
end function

playBossHurt = function(worldX)
	play snd.roar, 1, worldX, 1.2 + 0.4*rnd
end function

playBossDefeated = function
	play snd.bossDefeated, 1
end function

