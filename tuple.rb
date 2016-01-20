require_relative 'LotusRoot'
include Notation

# \tuplet x/y : [nth note]*x on [nth note]*y

dur = [1]*6
elm = dur.map{"@"}
tpl = [[3, 4, 1/4r]]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.pchShift = 12
# sco.gen
# sco.print
# sco.export("sco.txt")

def x_note_value(rto_num, rto_den, tpl_nval)

	duple_note = [*0..6].map{|e|
		x = 2**e
		[x, "#{PPQN*4/x}"]
	}

	dotted_note = [*1..5].map{|e|
		x = PPQN*4/(2**e)
		x = x.to_s + "."
		[2**e*3/2, "#{x}"]
	}

	n_values = (duple_note + dotted_note).sort{|x,y| x[0]<=>y[0]}
p n_values
	if rto_num==0
		nil
	else
	te = rto_num*rto_den*tpl_nval
	mn = Math.log2(te).to_i
p mn
			mn = PPQN/2**mn
p mn
		va = n_values.select{|v|	
				v[0]>=mn && (v[0]<=mn*te || Math.log2(te)%1==0)
			}
			va = va.map{|v|
				[Rational(v[0],mn) * Rational(PPQN, te), v[1]]
			}

		va += n_values.select{|du, nv| du==PPQN}.map{|du, nv| [Rational(du), nv]}
		Hash[*va.uniq.flatten]
	end
end


q = x_note_value(9, 4, 1/2r)
p q
p %w(8 8 16).map{|e| q.key(e)}.sigma