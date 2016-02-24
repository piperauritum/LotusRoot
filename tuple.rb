require_relative 'bin/LotusRoot'

dur = [*0..10].map{rand(16)+1}
clipbd(dur)
elm = dur.map{"@"}

tpl = [4]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.measure = [[[3],2]]
# sco.measure = [5]
# sco.finalBar = 4
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
