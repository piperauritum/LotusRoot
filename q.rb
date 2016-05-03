require_relative 'bin/LotusRoot'

pch = [*0..9].map{Array.new(3).map{Rational(rand(96),4)}.uniq}
dur = [*0..9].map{rand(20)+1}
elm = pch.map{|e| %W(@ r! @:64 @GRC16;#{rand(3)+1}; %128#{e.map{|f| f+5}}).at(rand(5))}
elm = pch.map{"@"}
tpl = [*0..99].map{rand(12)+2}
tpl = [12]
sco = Score.new(dur, elm, tpl, pch)
sco.metre = [*0..99].map{|e| [[rand(8)+1], 1/2r]}
sco.metre = [[[3],1/2r]]
sco.pitchShift = 12
sco.autoChordAcc = 0
sco.beamOverRest = 0
sco.fracTuplet = 0
# sco.tidyTuplet = 0
sco.gen
sco.print
sco.export("sco.txt")