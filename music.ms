// This module manages the background music, and also
// the game clock (since those are linked).

MUSIC_VOLUME = 0.25

mainLevelMusic = file.loadSound("bgm/chiptuned-part1.ogg")
bossLevelMusic = file.loadSound("bgm/chiptuned-part3.ogg")

startTimeValue = 0
startMusicTimeLeft = 0

_lastTimeShown = 0
_speed = 1

startMusic = function(music)
	Sound.stopAll
	music.play MUSIC_VOLUME, 0, 1
	outer._speed = 1
	outer.startTimeValue = time
	outer.startMusicTimeLeft = music.duration
end function

startMainLevel = function
	startMusic mainLevelMusic
end function

startBossLevel = function
	startMusic bossLevelMusic
end function

stop = function
	mainLevelMusic.stop
	bossLevelMusic.stop
end function

setPitch = function(factor=1)
	snd = mainLevelMusic
	if not snd.isPlaying then snd = bossLevelMusic
	if not snd.isPlaying then return
	snd.adjust MUSIC_VOLUME, 0, factor
	outer.startMusicTimeLeft = calcTimeLeft
	outer.startTimeValue = time
	outer._speed = factor
end function

calcTimeLeft = function
	elapsed = time - startTimeValue
	return startMusicTimeLeft - elapsed * _speed
end function

update = function(forceRedraw = false)
	// Calculate how much time is left.
	// (For now, assume no speedups!)
	outer.timeLeft = calcTimeLeft
	if timeLeft < 0 then outer.timeLeft = 0
	t = round(timeLeft)
	if t != _lastTimeShown or forceRedraw then
		_lastTimeShown = t
		s = floor(t / 60) + ":" + ("00" + (t % 60))[-2:]
		text.row = 25
		text.column = 32
		text.color = "#8888FF"
		text.print s
	end if
end function

if locals == globals then
	clear
	text.row = 20; print "Press 1, 2, or 3 to change speed."
	startBossLevel
	while true
		update
		yield
		if key.available then
			k = key.get
			if k == "1" then setPitch 1
			if k == "2" then setPitch 1.26
			if k == "3" then setPitch 1.5
			if k == "q" or k == char(27) then break
		end if
	end while
	stop
end if

