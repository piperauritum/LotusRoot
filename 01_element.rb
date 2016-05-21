﻿require_relative 'bin/LotusRoot'

# Elements will be unfold with Durations.
# Example:
# elm = ["@"]; dur = [3]
# => elm = ["@", "=", "="]

dur = [*0..49].map{rand(16)+1}

## note or rest
elm = dur.map{rand(2)==0 ? "r!" : "@"}

## insert LilyPond command
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