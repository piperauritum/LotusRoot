require_relative '../bin/LotusRoot'

## Simple notation: Beats will be divided automatically
mtr = [5, 4]		# Cyclic sequence
# mtr = [[[5], 1/2r]]

## Explicit description of beat structure
# mtr = [[[2, 3], 1]]
# mtr = [[[2, 3], 1/2r]]

## Default beat structures
# mtr = [*1 .. 16].map{|e| [MtrParam.new(e).beat, 1]}

## more examples...
# mtr = [*1 .. 16].map{|e| [[e], 1/2r]}
# mtr = [*1 .. 16].map{|e| [[e], 1/4r]}
# mtr = [*1 .. 16].map{|e| [[e], 1/8r]}

pp mtr

if Array === mtr[0]
	elm = ["r!"] * mtr.map{|e| e[0].sum}.sum
	tpl = [mtr[0][1].denominator]
else
	elm = ["r!"] * mtr.sum
	tpl = [1]
end

elm *= 2 if mtr.size != 16
dur = [1]
pch = [nil]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = mtr		# Metre
sco.gen
sco.print
sco.export("sco.txt")
