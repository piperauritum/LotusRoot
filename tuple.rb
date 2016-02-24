require_relative 'LotusRoot'

dur = [3,4,3,4,6]
elm = dur.map{"@"}
tpl = [4]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.measure = [[[2,2,1],1]]
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
