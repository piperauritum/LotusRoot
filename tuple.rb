require_relative 'bin/LotusRoot'

dur = [*0..40].map{rand(16)+1}
clipbd(dur)
elm = dur.map{|e| "@^\\markup{#{e}}"}
# elm = dur.map{|e| "@"}
# tpl = [[6,6,1/4r], [4,4,1/4r]]
tpl = [4]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.measure = [[[3,2],1]]
sco.measure = [5]
# sco.rtoTuplet = 0

# sco.finalBar = 4
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
