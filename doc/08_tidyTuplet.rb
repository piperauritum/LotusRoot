require_relative '../bin/LotusRoot'

dur = [*0 .. 99].map{rand(4) + 1}
elm = dur.map{"@"}
tpl = [8]
pch = [0]

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12
sco.metre = [[[4], 1/2r]]
# sco.tidyTuplet = 0		# Makes tuplets readable
sco.gen
sco.print
sco.export("sco.txt")
