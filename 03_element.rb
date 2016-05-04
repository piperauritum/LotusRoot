require_relative 'bin/LotusRoot'

dur = [*1..50].map{rand(16)+1}

## attack or rest
elm = dur.map{rand(2)==0 ? "r!" : "@"}

## with LilyPond command
# elm = elm.zip(dur).map{|e,d| e+"^\\markup{#{d}}"}
elm[0] += "TMP4;120;"	# tempo mark

p elm

tpl = [4]
pch = [0]

sco = Score.new(dur, elm, tpl, pch)
sco.pitchShift = 12
sco.gen
sco.print
sco.export("sco.txt")


