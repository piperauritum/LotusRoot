require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

dur = [*0..499].map{(rand(16)+1)}

elm = dur.map{%w(@ r! r! r!)[rand(4)]}
# elm = dur.map{[["@", 1], "r!"][rand(2)]}

clipbd([dur, elm])
# dur, elm = [[1,6,1],%w(@ r! @)]
tpl = [8]

pch = [24]
sco = Score.new(dur, elm, tpl, pch)
# sco.metre = [6]
sco.omitRest = [3/2r]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
sco.gen
sco.print
sco.export("sco.txt")