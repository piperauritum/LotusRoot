require_relative 'bin/LotusRoot'

dur = [*0..20].map{rand(12)+1}
clipbd(dur)
dur = [3, 11, 6, 6, 9, 12, 10]
elm = dur.map{"@"}
tpl = [6,5]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
# sco.measure = [[[2,1],2]]
sco.rtoTup = 0
# sco.measure = [3]
# sco.finalBar = 4
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
