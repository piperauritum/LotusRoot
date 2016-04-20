require_relative 'bin/LotusRoot'

# int tpl = div each beats
# ary tpl = explicit

tpl = [2]
dur = [*0..10].map{rand(8)+1}
clipbd(dur)
# elm = dur.map.with_index{|e,i| "@^\\markup{#{i}}"}
elm = dur.map{"@"}
pch = [0].add(12)
sco = Score.new(dur, elm, tpl, pch)
sco.measure = [6]

# sco.noTie = 0
# sco.fracTuplet = 0
# sco.dotDuplet = 0
# sco.finalBar = 5
# sco.fmRest = 0
# sco.noTie = 0
sco.gen
sco.print
sco.export("sco.txt")

e = [6]
if Fixnum===e
	a = [2]*(e/2)+[e%2]-[0]
	a = a.map{|e| e*2}
else
	a = e.map{|f|
		if Math.log2(f)%1==0 && f>2
			[4]*(f/4)
		elsif f%3==0
			[3]*(f/3)
		else
			[4]*(f/4)+[f%4]
		end
	}.flatten
end
p a