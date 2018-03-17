require_relative '../bin/LotusRoot'

pch = [[3,6,10],[3,6,10],[2,6,10],[3,6,10]]
elm = pch.map{"@"}
dur = [1]
tpl = [1]

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12
# sco.reptChordAcc = 0		# Repeats accidentals to the next chord
# sco.reptChordAcc = 1		# Except if the chord is immediately repeated
sco.gen
sco.print
sco.export("sco.txt")