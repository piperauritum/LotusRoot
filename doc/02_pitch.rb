require_relative '../bin/LotusRoot'

## Try commented lines by uncomment ##

## Diatonic scale
pch = [0, 2, 4, 5, 7, 9, 11]

## Chromatic scale
# pch = [*0..11]		# => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

## Quarter tone scale
# pch = [*0..23].map{|e| Rational(e, 2)}

## Eighth tone scale
# pch = [*0..47].map{|e| Rational(e, 4)} 

## Chord
# pch = [*0..11].map{|e| [0,5,10].map{|f| e+f}}

p pch

elm = pch.map{"@"}		# Linear sequence: All elements are needed
dur = [1]				# Cyclic sequence: Read repeatedly
tpl = [2]				# Cyclic sequence: Read repeatedly

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12						# Transposition
sco.accMode = 0							# Select accidentals mode
sco.gen
sco.print
sco.export("sco.txt")