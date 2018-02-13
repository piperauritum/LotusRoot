require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

pch = [12]
tpl = [[3,3,1/2r]]
dur = [*0..49].map{ rand(8)+1 }
elm = dur.map{["@", 1]}
clipbd([tpl, elm, dur])

sco = Score.new(dur, elm, tpl, pch)
sco.metre = [[[9], 1/2r]]
sco.omitRest = [1]
# sco.tidyTuplet = 0
sco.beamOverRest = 0
# sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")