require_relative 'bin/LotusRoot'

mtr = [*0..9].map{[[rand(3..8)], 1/4r]}

tpl = mtr.map{|e| [e[0][0]+rand(e[0][0]), e[0][0], e[1]]}

x, y = 0, 0
pch = [*0..99].map{
	a = [rand(-3..2), 0].max
	[*0..a].map{
		y += 5+x%2
		x+=1
		y%=24
	}
}

dur = pch.map{rand(1..3)}

elm = dur.map.with_index{|e,i|
	dyn = %w(fff ff f mf mp p pp ppp)[rand(8)]
	art = %w(^ - ! > .)[rand(5)]
	e<2 ? sel=3 : sel=5
	eee = %W(r! @ @GRC16;#{rand(3)+1}; @:32 %32[#{pch.on(i+1)}])[rand(sel)]
	eee += "-#{art}\\#{dyn} " unless eee=="r!"
	eee
}

p dur, elm, tpl, pch, mtr

sco = Score.new(dur, elm, tpl, pch)
sco.metre = mtr
sco.autoChordAcc = 0
sco.pitchShift = 12
sco.fracTuplet = 0
sco.gen
sco.print
sco.export("sco.txt")