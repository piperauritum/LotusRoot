require_relative 'bin/LotusRoot'

dur = [1, 15]
elm = %w(@ r!)
tpl = [2]
pch = [0]

sco = Score.new(dur, elm, tpl, pch)

sco.gen
sco.print

p note_value(4)