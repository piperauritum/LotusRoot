require_relative 'bin/LotusRoot'

mtl = [0,2,3,5,6,8,9,11]
pch = (0..7).to_a.map{|x|
	[0,2,3,5].map{|y|
		mtl[(x+y)%mtl.size]
	}
}
dur = [1,1,1,1,1,1,1,2]
tpl = [2,3,2,2]
elm = ["TMP4;48;@("] + ["@"]*6 + ["@)"]

sco = Score.new(dur, elm, tpl, pch)
sco.autoChordAcc = 0
sco.pitchShift = 12
sco.gen
sco.print
sco.export("sco.txt")