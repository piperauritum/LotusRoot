require_relative 'bin/LotusRoot'

met = [*1..16]
# met = [*1..16].map{|e| [[e], 1/2r]}
# met = [*1..16].map{|e| [[e], 1/4r]}
# met = [*1..16].map{|e| [[e], 1/8r]}

## explicit description of beat structure
def bt(q)
	if q<4
		[q]
	elsif q%3==0
		[3]*(q/3)
	elsif q%2==0
		[2]*(q/2)
	else
		[2]*(q/2)+[q%2]-[0]
	end
end

# met = [*1..16].map{|e| [bt(e), 1/2r]}

p met

if Array===met[0]
	dur = [met.map{|e| e[0].sigma}.sigma]
	tpl = [met[0][1].denominator]
else
	dur = [met.sigma]
	tpl = [1]
end

elm = ["r!"]
pch = [nil]

sco = Score.new(dur, elm, tpl, pch)
sco.metre = met		# metre
sco.gen
sco.print
sco.export("sco.txt")


