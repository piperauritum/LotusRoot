require_relative 'bin/LotusRoot'

pch = [*0..99].map{
	[*0..rand(2)+1].map{
		rand(192)/8.0
	}.uniq
}
dur = pch.map{rand(8)+1}
tpl = [*0..99].map{rand(15)+2}
elm = pch.map{
	%w(@\\ff-^ @\\f-> @\\mf-! @\\mp-. @\\p-- @\\pp-_ r!)[rand(7)]
}
elm = elm.map{|e| rand(4)==0 ? "@GRC8;#{rand(3)+1};" : e}

p dur, elm, tpl, pch

sco = Score.new(dur, elm, tpl, pch)
sco.autoChordAcc = 0
sco.pitchShift = 12
sco.metre = [*0..99].map{rand(3)>1 ? rand(4)+1 : [[[2]*(rand(3)+1),1].flatten,2]}
sco.gen
sco.export("sco.txt")