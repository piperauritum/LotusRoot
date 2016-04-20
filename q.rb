require_relative 'bin/LotusRoot'

# int tpl = div each beats
# ary tpl = explicit

tpl = [2]
dur = [*0..10].map{rand(8)+1}
clipbd(dur)
# elm = dur.map.with_index{|e,i| "@^\\markup{#{i}}"}
elm = dur.map{"@"}
pch = [0].add(12)
sco = Score.new(dur, elm, tpl, pch)
sco.measure = [6]

# sco.noTie = 0
# sco.fracTuplet = 0
# sco.dotDuplet = 0
# sco.finalBar = 5
# sco.fmRest = 0
# sco.noTie = 0
sco.gen
sco.print
sco.export("sco.txt")

