require_relative 'bin/LotusRoot'

## Repeats markup for each tied notes (@=)
elm = ["@= \\flageolet", "@"]

## Markup on the head of tied notes (#A..A#)
# elm = ["@= \\flageolet #A\\ppA#", "@"]

## Markup on the tail of tied notes (#Z..Z#)
# elm = ["@= \\flageolet #A\\pp\\<A# #Z~Z#", "@ \\flageolet \\f"]

dur = [23, 1]
tpl = [2]
pch = [0]

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 24
sco.gen
sco.print
sco.export("sco.txt")