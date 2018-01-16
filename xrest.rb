require_relative 'bin/LotusRoot'

# dur = [4, 8, 4]
# elm = %w(@ @ @)
dur = [1, 31]
elm = dur.map{"@"}
elm = %w(@ r!)
tpl = [8]
pch = [0]

sco = Score.new(dur, elm, tpl, pch)
sco.omitRest = [3/2r]
# sco.tidyTuplet = 0
sco.gen
sco.print
# sco.export("sco.txt")