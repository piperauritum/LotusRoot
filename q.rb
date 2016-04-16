require_relative 'bin/LotusRoot'

# int tpl = div each beats
# ary tpl = explicit

tpl = [6]
dur = [*1..20].map{rand(4)+1}
clipbd(dur)
dur = [2, 2, 1, 4, 2, 4, 1, 2, 3, 3, 1, 4, 1, 2, 1, 1, 4, 1, 4, 2]
elm = dur.map{"@"}
pch = [0].add(12)
sco = Score.new(dur, elm, tpl, pch)
# sco.measure = [[[2,2,2,2],2]]
# sco.noTie = 0
sco.fracTuplet = 0
sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")
