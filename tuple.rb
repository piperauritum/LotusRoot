require_relative 'bin/LotusRoot'

tpl = [*4..16].map{|e| [e,3,1/2r]}

# elm = dur.map{|e| "@^\\markup{#{e}}"}
dur = [*0..50].map{rand(3)+1}
elm = dur.map{|e| "@"}
pch = [12]
sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.measure = [3]

sco.fracTuplet = 0
# sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")

