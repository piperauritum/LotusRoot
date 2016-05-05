require_relative 'bin/LotusRoot'

## chromatic scale
pch = [*0..11]

## quarter tone scale
# pch = [*0..23].map{|e| Rational(e, 2)}

## eighth tone scale
# pch = [*0..47].map{|e| Rational(e, 4)}

## chord
# pch = [*0..11].map{|e| [0,5,10].map{|f| e+f}}

p pch

elm = pch.map{"@"}
dur = [1]
tpl = [2]

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12		# transposition
sco.accMode = 0			# select accidentals mode
sco.gen
sco.print
sco.export("sco.txt")


