require_relative 'bin/LotusRoot'

pch = [nil]
elm = ["r!\\fermata", "r!"]

dur = [3, 3]
tpl = [2]

mtr = [[[6], 1/2r]]
mtr = [3]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = mtr
# sco.omitRest = [3/2r]		# Rests of given note values will be exclude
# sco.wholeBarRest = 0		# Replaces to whole bar rests
sco.gen
sco.print
sco.export("sco.txt")