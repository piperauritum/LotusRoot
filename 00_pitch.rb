require_relative 'bin/LotusRoot'

### try commented lines by uncomment ###

## diatonic scale
pch = [0, 2, 4, 5, 7, 9, 11]

## chromatic scale
# pch = [*0..11]		# => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

## quarter tone scale
# pch = [*0..23].map{|e| Rational(e, 2)}

## eighth tone scale
# pch = [*0..47].map{|e| Rational(e, 4)} 

## chord
# pch = [*0..11].map{|e| [0,5,10].map{|f| e+f}}

p pch

elm = pch.map{"@"}		# linear sequence: all elements are needed
dur = [1]				# cyclic sequence: read repeatedly
tpl = [2]				# cyclic sequence: read repeatedly

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12						# transposition
sco.accMode = 0							# select accidentals mode
sco.gen
sco.print
sco.export("sco.txt")