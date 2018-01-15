require_relative 'bin/LotusRoot'

dur = [4, 8, 4]
elm = %w(@ @ @)
dur = [1, 31]
elm = %w(@ r!)
tpl = [8]
pch = [0]

sco = Score.new(dur, elm, tpl, pch)
sco.omitRest = [3/8r, 3/4r, 3/2r, 3]
sco.gen
sco.print
sco.export("sco.txt")