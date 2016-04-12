require_relative 'bin/LotusRoot'

# todo: tuplet_num_to_array
tpl = [[5,3,1/2r]]
# tpl = [5]
# tpl = [4]
dur = [1]*60
elm = ["@"]*60
pch = [12]
sco = Score.new(dur, elm, tpl, pch)
sco.measure = [[[3],2], [[2,1],2]]
sco.noTie = 0
sco.gen
sco.print
sco.export("sco.txt")

