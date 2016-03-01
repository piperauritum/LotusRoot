require_relative 'bin/LotusRoot'

dur = [*0..80].map{rand(6)+1}
clipbd(dur)
# dur = dur.map{|e| e*3}
elm = dur.map{|e| "@^\\markup{#{e}}"}
# elm = dur.map{|e| "@"}
tpl = [[4,3,1/2r],[5,3,1/2r]]
# tpl = [8]
pch = [12]

p note_value_dot([5,3,1/2r])

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.measure = [[[3,3],2]]
# sco.measure = [3]
sco.rtoTuplet = 0
# sco.dottedDuplet = 0

# sco.finalBar = 4
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")



