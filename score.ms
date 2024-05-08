// Manages the player score, lives, and similar state.

points = 0
coins = 0
gems = 0
lives = 2

heart = char(9829) + " "

reset = function
	outer.points = 0
	outer.coins = 0
	outer.gems = 0
	outer.lives = 2
	outer.timeBonus = 0
	draw
end function


draw = function
	text.row = 25
	text.column = 2
	text.color = "#FF8888"
	print heart * lives, " "*6
	
	text.column = 62
	text.color = "#FF88FF"
	print ("00000" + points)[-5:]
end function

addPoints = function(pointsToAdd)
	outer.points += pointsToAdd
	draw
end function

gotCoin = function(pointValue = null)
	if pointValue == null then pointValue = Coin.pointValue
	addPoints pointValue
	outer.coins += 1
end function

gotGem = function(pointValue = null)
	if pointValue == null then pointValue = Gem.pointValue
	addPoints pointValue
	outer.gems += 1
end function

spendLife = function
	outer.lives -= 1
	draw
end function
