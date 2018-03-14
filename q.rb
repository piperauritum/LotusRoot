require_relative 'bin/LotusRoot'


pch = [12]
# elm = [["@", 1]]*4
elm = ["@"]*5
dur = elm.map{2}

tpl = [5]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = [[[3], 1/2r]]
# sco.metre = [*1..12].map{|e| [[e], 1/2r]}
# sco.avoidRest = [2/3r]
# sco.finalBar = 10
sco.wholeBarRest = 0
# sco.dotDuplet = 0
# sco.noTieAcrossBeat = 0
sco.gen
sco.print
sco.export("sco.txt")

