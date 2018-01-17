require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

dur = [*0..99].map{(rand(16)+1)}

elm = dur.map{%w(@ r! r! r!)[rand(0)]}
elm = dur.map{[["@", 1], "r!"][rand(2)]}

clipbd([dur, elm])

tpl = [6]

pch = [24]
sco = Score.new(dur, elm, tpl, pch)
# sco.metre = [8]
# sco.omitRest = [3/8r, 3/4r, 3/2r, 3]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
sco.gen
sco.print
sco.export("sco.txt")