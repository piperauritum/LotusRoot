require_relative '../bin/LotusRoot'

pch = [*0 .. 11].map{|x| [0, 1, 5].map{|y| x + y}}
elm = pch.map{"@"}
dur = [1]
tpl = [1]

sco = Score.new(dur, elm, tpl, pch)
sco.autoChordAcc = 0	# Selects sharp or flat automatically
sco.pitchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
