require_relative 'bin/LotusRoot'

# int tpl = div each beats
# ary tpl = explicit

## TODO ##
tpl = [12]; dur = [*0..50].map{(rand(12)+1)};

# tpl = [12]; dur = [*0..50].map{(rand(4)+1)*3};
# tpl = [12]; dur = [*0..50].map{4};
# tpl = [15]; dur = [*0..50].map{3};

clipbd(dur)
elm = dur.map{"@"}
# elm = dur.map.with_index{|e,i| "@^\\markup{#{e}}"}
pch = [12]
sco = Score.new(dur, elm, tpl, pch)
# sco.measure = [[[5],1/2r]]
# sco.noTie = 0
sco.fracTuplet = 0
# sco.dotDuplet = 0
# sco.finalBar = 5
# sco.fmRest = 0
# sco.noTie = 0
sco.gen
sco.print
sco.export("sco.txt")



