require_relative 'bin/LotusRoot'
require_relative 'bin/_win32'

pch = [12]
dur = [1]
elm = [1,0,0,0,0,1,0,0,0] + [0]*9
elm = elm.map{|e| e==1 ? "@" : "r!"}
tpl = [2]


sco = Score.new(dur, elm, tpl, pch)
sco.metre = [[[3,3,3],1/2r]]
# sco.omitRest = [1]
# sco.tidyTuplet = 0
sco.beamOverRest = 0
# sco.gen
# sco.print
# sco.export("sco.txt")
# clipbd(sco.seq.look)

omit = [1]

seq = [[
[Event.new("@", [1/2r]), Event.new("r!", [[1/2r], 1/2r])],
[Event.new("r!", [[1/2r], 1/2r]), Event.new("@", [1/2r])],
[Event.new("r!", [[[1/2r], 1/2r], 1/2r])]
]]

# seq.each{|e| e.each{|f| p f }}
# puts "\s"

yet = true
while yet
	seq = seq.map{|e|
		e.map{|f|
			f.map{|g|
				if Array===g.du && omit.include?(g.du.flatten.sigma)
					g.du.map{|h| Event.new(g.el, h)}
				else
					g
				end
			}.flatten
		}
	}
	p seq.look
	
	yet = false
	seq.flatten.each{|e|
		yet = true if Array===e.du && omit.include?(e.du.flatten.sigma)
	}
end

seq.each{|e| e.each{|f| p f }}