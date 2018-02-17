require_relative 'bin/LotusRoot'

pch = [nil]
elm = ["r!\\fermata", "r!"]

## Rests will be connected
dur = [3, 3]
tpl = [2]
mtr = [[[6], 1/2r]]

## Explicit tuplet will divide the rests
# tpl = [[3, 3, 1/2r]]

## Also beat structure will divide it
# tpl = [2]
# mtr = [[[3, 3], 1/2r]]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = mtr
# sco.omitRest = [3/2r]		# Rests of given note values will be exclude
# sco.wholeBarRest = 0		# Replaces to whole bar rests
# sco.textReplace("fermata", "fermataMarkup")
							# \fermata does not work on whole bar rests
sco.gen
sco.print
sco.export("sco.txt")