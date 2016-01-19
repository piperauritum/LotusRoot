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

def new_note_value(tpl_rto, tpl_nval)

	vd = [*0..6].map{|e|	# duple notes
		x = 2**e
		[x, "#{PPQN*4/x}"]
	}

	vt = [*1..5].map{|e|	# dotted notes
		x = PPQN*4/(2**e)
		x = x.to_s + "."
		[2**e*3/2, "#{x}"]
	}

	val = (vd+vt).sort{|x,y| x[0]<=>y[0]}	# note values

	tpl_num = tpl_rto.numerator
	if tpl_num==0
		nil
	else
		min_val = Math.log2(tpl_num).to_i
		min_val = PPQN/2**min_val	

		va = val.select{|v|
			v[0]>=min_val && (v[0]<=min_val*tpl_num || Math.log2(tpl_num)%1==0)
		}
		va = va.map{|v|
			mul_val = Rational(v[0], min_val)
			unit_val = Rational(PPQN * tpl_nval * tpl_rto.denominator, tpl_num)
			p [mul_val , unit_val]
			[mul_val * unit_val, v[1]]
		}
		va += val.select{|v| v[0]==PPQN}.map{|v| [Rational(v[0]), v[1]]}
		Hash[*va.uniq.flatten]
	end
end


p new_note_value(3/4r, 1/4r)
