require_relative 'bin/LotusRoot'

pch = [12]
# elm = [["@", 1]]*4
elm = ["@"]*4
dur = elm.map{5}
tpl = [3]
# tpl = [6]

sco = Score.new(dur, elm, tpl, pch)
# sco.metre = [1,2,3]
# sco.metre = [*1..12].map{|e| [[e], 1/2r]}
sco.avoidRest = [2/3r]
sco.wholeBarRest = 0
# sco.noTieAcrossBeat = 0
sco.gen
sco.print
sco.export("sco.txt")