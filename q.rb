require_relative 'bin/LotusRoot'

pch = [12]
elm = [["@", 1]]*20
dur = elm.map{ rand(16)+1 }
tpl = [3]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = [3, [[9], 1/2r]]
# sco.metre = [*1..12].map{|e| [[e], 1/2r]}
sco.wholeBarRest = 0
sco.gen
# sco.print
sco.export("sco.txt")