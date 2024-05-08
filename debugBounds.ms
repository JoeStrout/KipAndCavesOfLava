// Little utility module that helps you debug bounding boxes
// by drawing them in a PixelDisplay overlay.
import "importUtil"
ensureImport "spriteControllers"
ensureImport "mathUtil"

disp = null

setup = function(displayIndex = 0)
	display(displayIndex).mode = displayMode.pixel
	outer.disp = display(displayIndex)
	disp.clear color.clear
end function

update = function(spriteDisp)
	if disp == null or display(disp.index).mode != displayMode.pixel then setup
	if spriteDisp == null then spriteDisp = spriteControllers.disp
	disp.clear color.clear
	disp.color = color.fuchsia
	for sp in spriteDisp.sprites
		b = sp.worldBounds
		if b == null then continue
		bbox = mathUtil.shiftPoly(b.corners, -spriteDisp.scrollX, -spriteDisp.scrollY)		
		disp.drawPoly bbox
	end for
end function

