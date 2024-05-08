// This module draws and manages the background layers.
// It uses just one display (number 7), and does everything
// with giant sprites.


setup = function
	display(7).mode = displayMode.sprite
	outer.disp = display(7)
	disp.clear
	
	outer.layerSprites = []  // list of sprites for each layer (0-3)
	outer.scrollSpeeds = []  // for each layer: [xfactor, yfactor]
	scrollSpeeds.push [0,0]
	scrollSpeeds.push [0.1, 0.01]
	scrollSpeeds.push [0.3, 0.03]
	scrollSpeeds.push [0.5, 0.05]

	names = "bg_wayback,bg_far,bg_mid,bg_near".split(",")
	for i in range(0,3)
		img = file.loadImage("pics/" + names[i] + ".png")
		sp = new Sprite
		sp.image = img
		sp.x = img.width/2
		sp.y = img.height/2
		disp.sprites.push sp
		sp2 = new Sprite
		sp2.image = img
		sp2.x = sp.x + img.width
		sp2.y = sp.y
		disp.sprites.push sp2
		layerSprites.push [sp, sp2]
	end for
end function


scrollTo = function(x, y)
	if y < 0 then y = 0
	imgHeight = layerSprites[0][0].image.height
	if y * scrollSpeeds[-1][1] > imgHeight - 640 then
		y = (imgHeight - 640) / scrollSpeeds[-1][1]
	end if
	for i in range(0,3)
		sprites = layerSprites[i]
		w = sprites[0].image.width
		sx = (x * scrollSpeeds[i][0]) % w
		sy = y * scrollSpeeds[i][1]
		sprites[0].x = w/2 - sx
		sprites[1].x = sprites[0].x + w
	end for
end function

if locals == globals then
	clear
	gfx.clear color.clear
	setup
	x = 0; y = 0
	while not key.pressed("escape")
		x += key.axis("Horizontal") * 20
		y += key.axis("Vertical") * 20
		scrollTo x, y
		yield
	end while
	key.clear
end if
