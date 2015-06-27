require_relative 'LotusRoot'

mtl = [0,2,3,5,6,8,9,11]
pch = (0..7).to_a.map{|x|
	[0,2,3,5].map{|y| mtl[(x+y)%mtl.size]}
}
dur = pch.map{1}
elm = pch.map{"@"}
elm[0] = "\\tempo 4 = 48 @"
tpl = [3,2]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.pchShift = 12
sco.export("sco.txt")