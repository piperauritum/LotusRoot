require_relative 'bin/LotusRoot'

# \tuplet x/y : [nth note]*x on [nth note]*y
# =begin
dur = [*0..90].map{rand(6)+1}
clipbd(dur)
# dur = [6,4,4,2]
elm = dur.map{"@"}
# tpl = [[6,6,1/4r],[4,4,1/4r]]
tpl = [4]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
# sco.beam = 0
# sco.measure = [[[2,3],1]]
sco.measure = [4]
# sco.finalBar = 4
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
# =end

# clipbd(sco.output)

# p note_value([5,4,1/4r])

