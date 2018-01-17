require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

dur = [*0..99].map{(rand(4)+1)*4}
# elm = dur.map{[["@" ,1], "r!"][rand(2)]}
elm = dur.map{["@", "r!", "r!", "r!"][rand(4)]}
tpl = [12]
pch = [24]

clipbd([dur, elm])
dur = [8, 4, 8, 4]
elm = ["r!", "r!", "r!", "@"]
# dur = [8,4]
# dur = [2,5,2,2,1]
# elm = dur.map{"@"}

dur = [8, 4]
elm = [ "r!", "@"]

sco = Score.new(dur, elm, tpl, pch)
# sco.omitRest = [3/2r, 3]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
sco.gen
sco.print
sco.export("sco.txt")