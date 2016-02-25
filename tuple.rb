require_relative 'bin/LotusRoot'

dur = [*0..20].map{rand(12)+1}
clipbd(dur)
dur = [11, 9, 10, ] # 7, 8, 5, 1, 6, 3, 10, 1, 5, 12, 3, 3, 9, 9, 8, 12, 8, 1]
elm = dur.map{"@"}
tpl = [3,4,5,6]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
# sco.measure = [[[2,1],2]]
sco.rtoTup = 0
# sco.measure = [5]
# sco.finalBar = 4
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
