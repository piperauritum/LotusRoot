require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

pch = [12]
tpl = [1]
# dur = [*0..19].map{ rand(16)+1 }
# elm = dur.map{ ["r!", ["@", 1]][rand(2)] }
# met = [*0..19].map{ [[rand(8)+1], Rational(1, 2**rand(2))] }
# elm = dur.map{ %w(r! @)[rand(2)] }
# met = [*0..99].map{[[rand(8)+1, rand(8)+1, rand(8)+1], 1/4r]}
# clipbd([dur, elm, met])

dur = [1]
elm = ["r!"]
met = [6]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = met
# sco.omitRest = [1.5]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
# sco.dotDuplet = 0
# sco.wholeBarRest = 0
sco.gen
sco.print
sco.export("sco.txt")