require_relative 'bin/LotusRoot'


dur = [*0..50].map{rand(8)+1}
clipbd(dur)
dur = [6, 5, 6, 8, 3, 5, 7, 5, 5, 7, 6, 4, 5, 6, 4, 1, 2, 2, 6, 1, 5, 8, 1, 5, 8, 6, 8, 6, 1, 6, 6, 5, 7, 6, 3, 1, 5, 5, 2, 4, 3, 1, 4, 7, 3, 7, 6, 2, 2, 8, 4]

# elm = dur.map{|e| "@^\\markup{#{e}}"}
elm = dur.map{|e| "@"}

tpl = [[3,5,1/2r]]*2+[[4,3,1/2r]]*2

pch = [12]
sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
# sco.measure = [[[3,3],2]]
sco.measure = [5,3]
sco.rtoTuplet = 0
# sco.dottedDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")



