require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

# TODO:
# rest tree
# tpl_param class
# div omitted rest = insert tpl

pch = [12]
dur = [*0..4].map{|e| rand(6)+1}
elm = dur.map{|e| ["r!", "@"][rand(2)]}
tpl = [4]
clipbd([dur, elm])

dur, elm = [[6], ["@"]]

sco = Score.new(dur, elm, tpl, pch)
# sco.metre = [[[3,3], 1/2r]]
sco.omitRest = [2,1]	# why??
# sco.omitRest = [2]
# sco.tidyTuplet = 0
# sco.beamOverRest = 0
sco.gen
sco.print
sco.export("sco.txt")
