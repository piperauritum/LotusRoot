require_relative 'bin/LotusRoot'

## Simple notation: Beats will be divided automatically
mtr = [5, 4]		# Cyclic sequence
# mtr = [[[5], 1/2r]]

## Explicit description of beat structure
# mtr = [[[2, 3], 1]]
# mtr = [[[2, 3], 1/2r]]

def bt(q)
	if q<4
		[q]
	elsif q%3==0
		[3]*(q/3)
	elsif q%2==0
		[2]*(q/2)
	else
		[2]*(q/2)+[q%2]-[0]
	end
end

## more examples
# mtr = [*1..16]
# mtr = [*1..16].map{|e| [[e], 1/2r]}
# mtr = [*1..16].map{|e| [[e], 1/4r]}
# mtr = [*1..16].map{|e| [[e], 1/8r]}
# mtr = [*1..16].map{|e| [bt(e), 1/2r]}

p mtr

if Array===mtr[0]
	dur = [mtr.map{|e| e[0].sigma}.sigma*2]
	tpl = [mtr[0][1].denominator]
else
	dur = [mtr.sigma*2]
	tpl = [1]
end

elm = ["r!"]
pch = [nil]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = mtr		# Metre
sco.gen
sco.print
sco.export("sco.txt")