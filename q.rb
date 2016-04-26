require_relative 'bin/LotusRoot'

# int tpl = div each beats
# ary tpl = explicit

## TODO ##
tpl = [[8,6,1/4r]]; dur = [*0..50].map{(rand(8)+1)};

clipbd(dur)
elm = dur.map{"@"}
# elm = dur.map.with_index{|e,i| "@^\\markup{#{e}}"}
pch = [12]
sco = Score.new(dur, elm, tpl, pch)
sco.measure = [3]
# sco.noTie = 0
sco.fracTuplet = 0
# sco.tidyTuplet = 0
sco.dotDuplet = 0
# sco.finalBar = 5
# sco.fmRest = 0
# sco.noTie = 0
sco.gen
sco.print
sco.export("sco.txt")



