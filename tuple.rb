require_relative 'LotusRoot'
include Notation

# \tuplet x/y : [nth note]*x on [nth note]*y

dur = [1,1,1]
elm = dur.map{"@"}
tpl = [3]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.pchShift = 12
sco.gen
# sco.print


qt = 16	# Pulses per quarter note
tpl_ratio = 3/2r
tpl_nval = 1/1r

d = dur.map{|e| qt * e * 1/tpl_ratio * tpl_nval}
# p d				# each note values
# p d.inject(:+)	# total note values

def note_value(rto_num, rto_den, tpl_nval)

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

	if rto_num==0
		nil
	else
		min_val = PPQN * tpl_nval
		va = n_values.select{|v|
			v[0]>=min_val && (v[0]<=min_val*rto_num || Math.log2(rto_num)%1==0)
		}
		va = va.map{|v|
			mul_val = Rational(v[0], min_val)
			unit_val = Rational(PPQN * tpl_nval * rto_den, rto_num)
			[mul_val * unit_val, v[1]]
		}
		va += n_values.select{|v| v[0]==PPQN}.map{|v| [Rational(v[0]), v[1]]}
		Hash[*va.uniq.flatten]
	end
end

p note_value(6, 4, 1/2r)