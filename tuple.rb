require_relative 'bin/LotusRoot'

dur = [*0..10].map{(rand(6)+1)*3}
clipbd(dur)

elm = dur.map{|e| "@^\\markup{#{e}}"}
# elm = dur.map{|e| "@"}
tpl = [[12,12,1/8r]]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.measure = [[[6],2]]
# sco.measure = [2]
sco.rtoTuplet = 0

# sco.finalBar = 4
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
