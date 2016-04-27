require_relative 'bin/LotusRoot'

tpl = [*4..16].map{|e| [e,4,1/4r]}
# tpl = tpl[8..-1]
# elm = dur.map{|e| "@^\\markup{#{e}}"}
dur = [*0..50].map{rand(8)+1}
clipbd(dur)
elm = dur.map{|e| "@^\\markup{#{e}}"}
pch = [12]
sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
# sco.metre = [3]

sco.fracTuplet = 0
# sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")

