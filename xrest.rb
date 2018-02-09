require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

pch = [12]
# dur = [*0..9].map{|e| rand(20)+1}
# elm = [*0..9].map{|e| rand(2)}
# elm = elm.map{|e| e==1 ? "@" : "r!"}
tpl = [4]
dur, elm = [[4, 2, 2], ["r!", "r!", "@"]]
clipbd([dur, elm])

sco = Score.new(dur, elm, tpl, pch)
# sco.metre = [[[3,3,3],1/2r]]
sco.omitRest = [1.5]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
sco.gen
sco.print
sco.export("sco.txt")
