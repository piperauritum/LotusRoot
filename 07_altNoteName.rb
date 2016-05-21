require_relative 'bin/LotusRoot'

pch = [*0..11].map{|e| [0,1].add(3*e)}.flatten
elm = pch.map{"@"}
dur = [1]
tpl = [1]

## Note names which will be replaced
alt = [[1, "des"], [3, "ees"], [10, "bes"]]

## In other words
# alt = [[1, 3, 10], %w(des ees bes)].transpose

## Over an octave (note the effect of .pitchShift)
# alt = [[13, 15, 10], %w(des ees bes)].transpose

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12
sco.accMode = 0
sco.altNoteName = alt	# Replacing note names
sco.gen
sco.print
sco.export("sco.txt")


