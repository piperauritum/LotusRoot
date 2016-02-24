require_relative 'bin/LotusRoot'

# \tuplet x/y : [nth note]*x on [nth note]*y
# =begin
dur = [*0..80].map{rand(16)+1}
clipbd(dur)
elm = dur.map{"@"}

tpl = [4]
# tpl = [[6,6,1/4r],[4,4,1/4r]]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
# sco.beam = 0
 sco.measure = [[[3,2],1]]
# sco.measure = [5]
# sco.finalBar = 4
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
# =end

# clipbd(sco.output)

# p note_value([5,4,1/4r])

