require_relative 'LotusRoot'

mtl = [0,2,3,5,6,8,9,11]
pch = (0..7).to_a.map{|x|
	[0,2,3,5].map{|y|
		mtl[(x+y)%mtl.size]
	}
}
dur = pch.map{1}
tpl = [2]
elm = ["TMP4;48;@(", ["@"]*6, "@)"].flatten

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")