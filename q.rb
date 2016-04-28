require_relative 'bin/LotusRoot'

# int tpl = div each beats
# ary tpl = explicit

### TODO
# altNoteName for n-octaves
# raise input error

tpl = [4]
pch = [*0..72]
dur = pch.map{1}
# clipbd(dur)
# elm = dur.map{rand(2)==0 ? "@GRC16;#{rand(8)+1};" : "r!"}
# elm = pch.map{|e| ["%32[#{e+2}]", "r!"]}.flatten
# elm = dur.map.with_index{|e,i| "@^\\markup{#{e}}"}
# elm[0] += "TMP4;666;" 
elm = pch.map{"@"}
sco = Score.new(dur, elm, tpl, pch)
sco.beam = 0
# sco.pitchShift = 12
# sco.autoAcc = 0
# sco.chordAcc = 0
# sco.accMode = 0
sco.altNoteName = [[1,12+3,24+6],%w(des ees ges)].transpose
# sco.metre = [*1..16].map{|e| [[e],1/4r]}
# sco.metre = [[[5],1/2r]]
# sco.noTie = 0
# sco.fracTuplet = 0
# sco.tidyTuplet = 0
# sco.dotDuplet = 0
# sco.finalBar = 5
# sco.noTie = 0
sco.gen
sco.print
sco.export("sco.txt")

