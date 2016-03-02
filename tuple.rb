require_relative 'bin/LotusRoot'

d = [*1..15].map{|e| [16-e, e]}.flatten
d = [16]
t = [*2..16]
tpl = []
t.each{|tt|
	d.each{|dd|
		tpl << [tt, dd, 1/4r]
	}
}

dur = [1]*tpl.transpose[0].sigma
elm = dur.map{|e| "@"}
# elm = dur.map{|e| "@^\\markup{#{e}}"}
dur = dur.map{rand(8)+1}

pch = [12]
sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
# sco.measure = [[[3,3],2]]

sco.fracTuplet = 0
# sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")
