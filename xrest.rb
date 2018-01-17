require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

dur = [*0..99].map{rand(8)+1}
# elm = dur.map{[["@" ,1], "r!"][rand(2)]}
elm = dur.map{["@", "r!", "r!", "r!"][rand(4)]}
tpl = [2]
pch = [24]

clipbd([dur, elm])

# dur, elm = [[6,1], %w(r! @)]

sco = Score.new(dur, elm, tpl, pch)
sco.omitRest = [3/2r, 3]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
sco.gen
sco.print
sco.export("sco.txt")