﻿require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

pch = [12]
tpl = [4]
dur = [25, 1]
elm = ["r!", "@"]
# met = [*0..99].map{[[rand(8)+1, rand(8)+1, rand(8)+1], 1/4r]}
# clipbd(met)

sco = Score.new(dur, elm, tpl, pch)
sco.metre = [5]
# sco.omitRest = [1]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
# sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")