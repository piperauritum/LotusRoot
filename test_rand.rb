require_relative 'bin/LotusRoot'

chd = [2,3,2,1]*3
chd = chd.inject([0]){|s,e|
	n = s.last+e
	s << n
	s
}
 
pch = Array.new(120).map{Array.new(rand(4)+3).map{chd[rand(12)]}.uniq}
dur = pch.map{rand(4)+2}
elm = pch.map{rand(10)==0 ? "@" : ["@-.", 1]}
tpl = [5]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = pch.map{|e| [[rand(3)+3],1/4r]}
sco.pitchShift = 12
sco.altNoteName = [[8,10], %w(aes bes)].transpose
sco.fracTuplet = 0
sco.gen
sco.print
sco.export("sco.txt")