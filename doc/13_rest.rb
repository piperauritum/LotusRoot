require_relative '../bin/LotusRoot'

pch = [12]
elm = %w(r!\\fermata r! @ @ r!)			# Plain rests are automatically unioned
# elm = %w(r!\\fermata r!foo @ @ r!)	# An example of the way of divide the rest
dur = [1, 5, 1, 1, 3]					# The last bar will be filled with rests automatically
tpl = [2, 2, 3, 3]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = [4, [[6], 1/2r]]
# sco.avoidRest = [2/3r, 1/3r]			# Rests of given note values will be excluded
# sco.wholeBarRest = 0					# Replaces to Whole-bar rests
sco.textReplace("foo", "")
sco.gen
sco.print
sco.export("sco.txt")