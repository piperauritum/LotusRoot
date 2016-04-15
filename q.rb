require_relative 'bin/LotusRoot'

# int tpl = div each beats
# ary tpl = explicit

tpl = [[9,8,1/2r]]
dur = [*1..20].map{rand(8)+1}
clipbd(dur)
elm = dur.map{"@"}
pch = [0].add(12)
sco = Score.new(dur, elm, tpl, pch)
me = [*1..48].map{|e| [[e],4]}
# sco.measure = me
# sco.noTie = 0
sco.fracTuplet = 0
sco.dotDuplet = 0
sco.gen
sco.print
sco.export("sco.txt")
