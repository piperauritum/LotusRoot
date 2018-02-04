require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

pch = [12]
dur = [1]
elm = [1,0,0,0,0,1,0,0,0] + [0]*9
elm = elm.map{|e| e==1 ? "@" : "r!"}
tpl = [2]


sco = Score.new(dur, elm, tpl, pch)
sco.metre = [[[3,3,3],1/2r]]
# sco.omitRest = [3/2r]
# sco.tidyTuplet = 0
sco.beamOverRest = 0
sco.gen
sco.print
sco.export("sco.txt")