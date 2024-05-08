grad = file.loadImage("pics/lava_gradient.png")

bubbleColor = "#fe7c1c"
topColor = "#fef51d"
bottomColor = grad.pixel(0,0)

bubbleXM = [
  [25, 50, 100, 120],
  [40, 80, 110],
  [20, 45, 105, 115],
  [30, 75, 115]]
bubbleYM = [
  [70, 30, 110, 40],
  [80, 20, 95],
  [25, 75, 42, 100],
  [35, 100, 50]]
bubbleRM = [
  [6, 3, 8, 4],
  [8, 4, 6],
  [3, 6, 8, 4],
  [7, 4, 5]]

surfHeight = function(x, t)
	// return height of surface (generally around 42) from
	// top of image, at pixel x on frame t.
	return 42 + 
	  3 * sin(x/128 * 2*pi) * sin(t/15 * 2*pi) +
	  2 * sin(3*x/128 * 2*pi) * sin((t+2)/10 * 2*pi) +
	  1 * sin(5*x/128 * 2*pi) * sin((t+1)/6 * 2*pi)
end function

drawFrame = function(x, y, t)
	gfx.fillRect x,y,128,256, color.clear
	for i in range(0,127)
		top = surfHeight(i, t)
		gfx.drawImage grad, x+i, y+128, 1, 128,
		  0, grad.height - 128 + top-42, 1, 128
		if i % 10 == 0 then yield
	end for
	gfx.fillRect x, y, 128, 128, bottomColor
	for i in bubbleX.indexes
		for yoffset in [0,128]
			bx = bubbleX[i]
			by = bubbleY[i] - yoffset - 128/30 * (t % 30)  // note: top-down
			r = bubbleR[i]
			top = surfHeight(bx, t)
			if by-r < top - 3 then
				by += 256
			end if
			if by < top - 2 then
				gfx.color = topColor
			else if by < top + 4 then
				gfx.color = color.lerp(bubbleColor, topColor, 0.5)
			else
				gfx.color = bubbleColor
			end if
			gfx.fillEllipse x + bx-r, y + 256-by -r, r*2, r*2
		end for
	end for
end function

clear
x = 0; y = 0; t = 0
frames = []
for t in range(0,30)
	gfx.fillRect x, y, 128*4, 256, color.clear
	for version in range(0,3)
		bubbleX = bubbleXM[version]
		bubbleY = bubbleYM[version]
		bubbleR = bubbleRM[version]
		drawFrame x + 128*version, y, t
	end for
	frames.push gfx.getImage(x, y, 128*4, 256)
end for

t = 0
while true
	gfx.fillRect 960-256, 640-256, 256, 256, color.clear
	gfx.drawImage frames[t], 960-128, 640-256
	gfx.drawImage frames[t], 960-128*2, 640-256
	t = (t + 1) % frames.len
	wait 0.1
end while
