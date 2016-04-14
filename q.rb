require_relative 'bin/LotusRoot'

# todo: tuplet_num_to_array
# int tpl = div each beats
# ary tpl = explicit

tpl = [[7,5,1/2r]]
tpl = [3, [3,3,3/2r]]
tpl = [6]
dur = [1]*500
elm = dur.map{"@"}
pch = [0,2,4,5,7,9].add(12)
sco = Score.new(dur, elm, tpl, pch)
# sco.measure = [*1..2].map{|e| [[5],2]}
sco.measure = [*1..32].map{|e| [[e],4]}
# sco.noTie = 0
sco.fracTuplet = 0
sco.gen
sco.print
sco.export("sco.txt")

# correct:
# \time 5/8 \fractpl \tuplet 6/5 {c'4 c' c' }
# strange:
# \time 5/8 \fractpl \tuplet 3/5 {c'8 c' c' }

