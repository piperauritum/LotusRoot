require_relative 'bin/LotusRoot'

pch = [12]
elm = %w(@ @ r! @)
dur = [1]
tpl = [[4, 3, 1]]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = [3]
# sco.dotDuplet = 0			# Rewrites 2:3 tuplets into dotted duplets
# sco.beamOverRest = 0		# Beams over rests
# sco.namedMusic = "name"	# Change the name of music segment
# sco.noMusBracket = 0		# Without segment bracket
sco.gen
sco.print
sco.export("sco.txt")