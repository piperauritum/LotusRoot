require_relative 'bin/LotusRoot'

dur = [1, 15]
elm = %w(@ r!)
tpl = [4]
pch = [0]

sco = Score.new(dur, elm, tpl, pch)
sco.omitRest = [3/4r, 3/2r, 3]
sco.gen
sco.print
sco.export("sco.txt")