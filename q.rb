require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

pch = [12]
tpl = [4]
elm = [*0..50].map{ %w(r! @)[rand(2)]}
dur = elm.map{ rand(16)+1 }
clipbd([dur, elm])

sco = Score.new(dur, elm, tpl, pch)
sco.metre = [5]
# sco.omitRest = [1.5]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
# sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")