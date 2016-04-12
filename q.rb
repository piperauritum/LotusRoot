require_relative 'bin/LotusRoot'

tpl = [5,5,5,[5,3,1/2r]]
dur = [1]*60
elm = ["@"]*60
pch = [12]
sco = Score.new(dur, elm, tpl, pch)
sco.measure = [3, [[3],2]]
sco.noTie = 0
sco.gen
sco.print
sco.export("sco.txt")

