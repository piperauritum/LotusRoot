require_relative 'bin/LotusRoot'

tpl = [4]
dur = [2,10]
elm = ["@",["@:32", 3]]
pch = [12]
sco = Score.new(dur, elm, tpl, pch)
# sco.measure = [3, [[2,1],2]]
sco.noTie = 0
sco.gen
sco.print
sco.export("sco.txt")

