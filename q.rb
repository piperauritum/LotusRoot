require_relative 'bin/LotusRoot'

# int tpl = div each beats
# ary tpl = explicit

### TODO
# altNoteName for n-octaves
# raise input error

tpl = [7]
pch = [*0..99].map{
	a = Array.new(rand(8)+1)
	a.map{rand(24)}.uniq
}
dur = [1]*1000
# clipbd(dur)
elm = dur.map{rand(2)==0 ? "@" : "r!"}
# elm = dur.map.with_index{|e,i| "@^\\markup{#{e}}"}

sco = Score.new(dur, elm, tpl, pch)
sco.beam = 0
# sco.pitchShift = 12
sco.autoAcc = 0
sco.chordAcc = 0
# sco.accMode = 0
# sco.altNoteName = [[1,3,6,10],%w(des ees fis bes)].transpose
sco.metre = [*0..99].map{|e| [[rand(16)+1],1/4r]}

# sco.noTie = 0
sco.fracTuplet = 0
# sco.tidyTuplet = 0
# sco.dotDuplet = 0
# sco.finalBar = 5
# sco.noTie = 0
sco.gen
sco.print
sco.export("sco.txt")

