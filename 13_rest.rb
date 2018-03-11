require_relative 'bin/LotusRoot'

dur = [10, 1]
elm = %w(r! @)
tpl = [2]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = [6]
# sco.avoidRest = [2/3r]		# Rests of given note values will be excluded

=begin
dur = [*1..32]
elm = dur.map{"r!"}
tpl = [1]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = dur # .map{|e| [[e], Rational(1, tpl[0])]}
# sco.wholeBarRest = 0		# Replaces to whole bar rests
=end

sco.gen
sco.print
sco.export("sco.txt")