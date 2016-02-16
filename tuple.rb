require_relative 'bin/LotusRoot'
include Notation

# \tuplet x/y : [nth note]*x on [nth note]*y
# =begin
dur = [1]*3
elm = dur.map{rand(2)==0 ? "@" : "r!"}
elm = dur.map{"rrr"}
tpl = [[5, 1/4r]]

pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.beam = 0
sco.measure = [2]
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
# =end

clipbd(sco.output)

# p note_value([5,4,1/4r])