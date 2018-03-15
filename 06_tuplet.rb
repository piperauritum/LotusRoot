require_relative 'bin/LotusRoot'

## Simple notation: Division of a quarter note
mtr = [*1..16].map{|e| [[e], 1/2r]}
tpl = [6]
# tpl = [5]
# tpl = [4]

## Explicit description of beat structure
=begin
tpl = [5]
mtr = [*1..16].map{|e|
	bt = [3]*(e/3)+[e%3]-[0]
	[bt, 1/2r]
}
=end

## Explicit notation: ratio and unit duration
=begin
tpl = [[5, 3, 1/2r], [5, 4, 1/4r], [5, 4, 1/8r]]
mtr = [[[3], 1/2r]]
=end

p tpl, mtr

dur = [1]*1000
elm = dur.map{"@"}
pch = [0]

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12
sco.metre = mtr			# Metre
sco.fracTuplet = 0		# Tuplet numbers in fraction form
sco.finalBar = 16		# The last bar number
sco.gen
sco.print
sco.export("sco.txt")