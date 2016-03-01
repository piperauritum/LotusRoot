require_relative 'bin/LotusRoot'

dur = [1]*12
dur += [*0..50].map{rand(12)+1}
clipbd(dur)
# dur = [*0..50].map{1}

# elm = dur.map{|e| "@^\\markup{#{e}}"}
elm = dur.map{|e| "@"}

tpl = [[3,5,1/2r]]

pch = [12]
sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
# sco.measure = [[[3,3],2]]
sco.measure = [5]
sco.rtoTuplet = 0
sco.dottedDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")



