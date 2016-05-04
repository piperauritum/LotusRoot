require_relative 'bin/LotusRoot'

# duration 
dur = [2,1,1]*35

# tuplet
tpl = [*2..8].map{|e| [e]*4}.flatten

p dur, tpl

elm = dur.map{"@"}
pch = [0]

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12
sco.gen
sco.print
sco.export("sco.txt")


