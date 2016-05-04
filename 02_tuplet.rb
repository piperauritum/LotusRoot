require_relative 'bin/LotusRoot'

## simple tuplet notation
tpl = [5]
met = [*1..16].map{|e| [[e], 1/2r]}

## explicit description of beat structure
=begin
tpl = [5]
met = [*1..16].map{|e|
	bt = [2]*(e/2)+[e%2]-[0]
	[bt, 1/2r]
}
=end

## explicit tuplet notation
=begin
tpl = [[5,3,1/2r], [5,4,1/4r], [5,4,1/8r]]
met = [[[3], 1/2r]]
=end

p met

dur = [1]*1000
elm = dur.map{"@"}
pch = [0]

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12
sco.metre = met			# metre
sco.fracTuplet = 0		# tuplet numbers in fraction form
sco.finalBar = 16		# the last bar number
sco.gen
sco.print
sco.export("sco.txt")


