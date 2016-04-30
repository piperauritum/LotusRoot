require_relative 'bin/LotusRoot'

# todo
# tremolo
# fingered trem

dur = [*0..99].map{rand(8)+1}

pch = dur.map{Array.new(rand(5)+1).map{rand(24)}}

elm = pch.map{|e|
	%W(@ r! @:64 @GRC16;#{rand(4)+1}; ).at(rand(4))
}
# %64#{e.map{|f|f+5}} 
tpl = [*3..7]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = [*1..8].map{|e| [[e],1/2r]}
sco.pitchShift = 12
sco.autoChordAcc = 0
sco.beamOverRest = 0
sco.fracTuplet = 0
sco.gen
sco.print
sco.export("sco.txt")

