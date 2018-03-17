require_relative '../bin/LotusRoot'

pca = [*0..23].map{|e| e/2.0}	# Applies on quarter tones
pch = [*1..11].map{|n|			# ... and chromatic intervals
	pca.map{|e| [e, e+n]}
}.flatten.each_slice(2).to_a
dur = pch.map{1}
elm = pch.map{"@=HOGE"}
tpl = [1]

sco = Score.new(dur, elm, tpl, pch)
sco.accMode = 0
sco.autoChordAcc = 1	# Aligns the degrees of dyads
sco.textReplace(/<(\S+?) (\S*?)>([\d|\.]*?)HOGE/, "<\\1 \\2\\harmonic>\\3")	# Rewrites into stopped harmonics
sco.pitchShift = 12
sco.gen
sco.print
sco.export("sco.txt")