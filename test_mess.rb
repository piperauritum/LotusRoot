require_relative 'bin/LotusRoot'

pch = [*0..99].map{
	Array.new([rand(10)-4, 1].max).map{
		Rational(rand(96),4)
	}.uniq
}

dur = pch.map{[rand(12)-4,1].max}

elm = pch.map.with_index{|e,i|
	dyn = %w(fff ff f mf mp p pp ppp).at(rand(8))
	art = %w(^ - ! > .).at(rand(5))
	eee = %W(r! @ @:128 @GRC16;#{rand(4)+1}; %128[#{pch.on(i+500)}]).at(rand(5))
	eee += "-#{art}\\#{dyn} " unless eee=="r!"
	eee
}

tpl = pch.map{rand(10)+3}

def bt(q)
	if q<4
		[q]
	elsif q%3==0
		[3]*(q/3)
	elsif q%2==0
		[2]*(q/2)
	else
		[2]*(q/2-1)+[3]
	end
end

met = pch.map{|e| [bt(rand(12)+1), 1/2r]}

p dur, elm, tpl, pch, met

sco = Score.new(dur, elm, tpl, pch)
sco.metre = met
sco.autoChordAcc = 0
sco.pitchShift = 12
sco.fracTuplet = 0
sco.gen
sco.print
sco.export("sco.txt")


