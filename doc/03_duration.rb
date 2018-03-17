require_relative '../bin/LotusRoot'

## Durations are fit into Tuplets ##

dur = [2, 1, 1]
# dur = [3, 1]

## tuplets
tpl = [*2..8].map{|e| [e]*4}.flatten

p dur, tpl

elm = dur.map{|e| "@"}*35
# elm = dur.map{|e| "@_\\markup{#{e}}"}*35

pch = [0]		# Cyclic sequence: Read repeatedly

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12
sco.gen
sco.print
sco.export("sco.txt")