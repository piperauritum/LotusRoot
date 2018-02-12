require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

pch = [12]
# tpl = [*0..99].map{ rand(6)+3}
tpl = [6]
elm = [*0..19].map{ %w(r! @)[rand(2)]}
dur = elm.map{ rand(4)+1 }
clipbd([tpl, elm, dur])
tpl, elm, dur = [[6], ["@", "r!", "@", "r!", "r!", "r!", "r!", "r!", "r!", "r!", "r!", "@", "@", "@", "@", "r!", "r!", "r!", "r!", "r!"], [4, 4, 4, 2, 1, 2, 4, 4, 2, 2, 2, 2, 2, 4, 4, 3, 4, 2, 3, 3]]
sco = Score.new(dur, elm, tpl, pch)
sco.metre = [2]
# sco.metre = [*0..99].map{ [[rand(10)+1], 1/4r] }
# sco.omitRest = [1.5]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
# sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")