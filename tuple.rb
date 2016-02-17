require_relative 'bin/LotusRoot'
include Notation

# \tuplet x/y : [nth note]*x on [nth note]*y
# =begin
dur = [*0..10].map{rand(8)+1}
elm = dur.map{"@"}
tpl = [2]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
# sco.beam = 0
sco.measure = [3,4]
# sco.finalBar = 2
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
# =end

# clipbd(sco.output)

# p note_value([5,4,1/4r])

