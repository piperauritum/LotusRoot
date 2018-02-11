require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

pch = [12]
tpl = [4,5,6,7]
elm = [*0..9].map{ %w(r! @)[rand(2)]}
dur = elm.map{ rand(8)+1 }
clipbd([dur, elm])
# dur, elm = [[10, 11, 14, 9, 11, 4, 16, 6, 6, 7], ["@", "r!", "@", "r!", "@", "r!", "@", "@", "@", "r!"]]
sco = Score.new(dur, elm, tpl, pch)
sco.metre = [*0..99].map{ [[rand(10)+1], 1/4r] }
# sco.omitRest = [1.5]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
# sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")