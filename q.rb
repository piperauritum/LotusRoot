require_relative 'bin/LotusRoot'


pch = [12]
elm = ["@"]*15
dur = [1]
tpl = [5,4,3]
mtr = [[[2,2,2], 1/2r]]
mtr = [[[6], 1/2r]]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = mtr
# sco.avoidRest = [2/3r, 1]
# sco.wholeBarRest = 0
# sco.dotDuplet = 0
# sco.noTieAcrossBeat = 0
sco.gen
p sco.metre
sco.print
sco.export("sco.txt")

