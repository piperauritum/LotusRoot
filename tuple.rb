require_relative 'LotusRoot'
include Notation

# \tuplet x/y : [nth note]*x on [nth note]*y
=begin
dur = [1]*6
elm = dur.map{"@"}
tpl = [[6, 5, 1/4r]]
pch = [12]

sco = Score.new(dur, elm, tpl, pch)
sco.autoAcc = 0
sco.pchShift = 12
sco.gen
sco.print
sco.export("sco.txt")
=end


def xnote_value(tpl)

	if Array === tpl
		rto_nu, rto_de, unit_nt = tpl
	else
		rto_nu = tpl
		rto_de = 2**Math.log2(tpl).to_i
		unit_nt = Rational(1, rto_de)
	end

	duple_note = [*-4..2].map{|e|
		x = 2**e
		[x, "#{(4/x).to_i}"]
	}

	dotted_note = [*-4..0].map{|e|
		x = 2**e
		[Rational(x*3), "#{(2/x).to_i}."]
	}

	notation = (duple_note + dotted_note).sort{|x,y| x[0]<=>y[0]}

	if rto_nu==0
		nil
	else
		unit_va = unit_nt
		nt = notation.select{|dur, note|	
			dur>=unit_va && (dur<=unit_va*rto_nu || Math.log2(rto_nu)%1==0)
		}

		nt = nt.map{|dur, note|
			[Rational(rto_de, rto_nu)*dur, note]
		}

		nt += notation.select{|dur, note|
			dur==rto_de*unit_nt
		}.map{|dur, note|
			[Rational(dur), note]
		}
		
		Hash[*nt.uniq.flatten]
	end
end

 tpl = [5, 4, 1/4r]
 p xnote_value(tpl)