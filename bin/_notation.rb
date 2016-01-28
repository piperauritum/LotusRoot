class Event
	attr_accessor :el, :va
	
	def initialize(e, v)
		@el, @va = e, v		
	end
	
	def ar
		[@el, @va]
	end
end


module Notation
	PPQN = 1	# Pulses per quarter note
=begin	
	def note_value
		vd = [*0..6].map{|e|	# duple notes
			x = 2**e
			[x, "#{PPQN*4/x}"]
		}

		vt = [*1..5].map{|e|	# dotted notes
			x = PPQN*4/(2**e)
			x = x.to_s + "."
			[2**e*3/2, "#{x}"]
		}

		val = (vd+vt).sort{|x,y| x[0]<=>y[0]}

		ha = [*1..16].map{|tpl|
			mn = Math.log2(tpl).to_i
			mn = PPQN/2**mn	
			va = val.select{|v|	
				v[0]>=mn && (v[0]<=mn*tpl || Math.log2(tpl)%1==0)
			}
			va = va.map{|v|
				[Rational(v[0],mn) * Rational(PPQN, tpl), v[1]]
			}
			va += val.select{|v| v[0]==PPQN}.map{|v| [Rational(v[0]), v[1]]}
			Hash[*va.uniq.flatten]
		}
		ha.insert(0, nil)
	end
=end

	def note_value(tpl)

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
	
	
	def note_name(pc, acc=0)	
		nname = [
			%w(c cis d dis e f fis g gis a ais b),
			%w(c des d ees e f ges g aes a bes b),
		]
		
		# quarter tone
		qname = %w(cih deh dih eeh feh fih geh gih aeh aih beh ceh)
		
		# eighth tone
		ename = [
			%w(ci cise cisi de di dise eesi ee ei fe fi fise
			fisi ge gi gise gisi ae ai aise besi be bi ce),
			%w(ci dese desi de di eese eesi ee ei fe fi gese
			gesi ge gi aese aesi ae ai bese besi be bi ce),
		]

		if pc%1 == 0.5
			na = qname[(pc%12).to_i]
		elsif pc%0.5 == 0.25
			na = ename[acc][(pc%12-0.25)*2]
		else
			na = nname[acc][pc%12]
		end

		otv = (pc/12.0).floor
		otv += 1 if na == "ceh" || na == "ce"
		
		otv.abs.times{
			pc>0 ? na+="'" : na+=","
		}	
		
		na
	end
	

	def auto_accmode(chord, mode)
		mo = mode
		am = chord.map{|x| x%12}
		[0,2,5,7,9].each{|e|			
			mo = 1 if am.include?(e) && am.include?(e+1)
		}
		[2,4,7,9,11].each{|e|
			mo = 0 if am.include?(e) && am.include?(e-1)
		}
		mo
	end
	
	
	def natural?(pc)
		[0,2,4,5,7,9,11].include?(pc%12)
	end
	
	
	def pitch_shift(pch, sum)
		pch.add(sum)
	end
	
	
	def chk_range(pch, a, b)
		pcs = pch.map{|e| Array === e ? e : [e]}-[[nil]]
		ans = true
		pcs.each{|e|
			range = [a, b]
			if e.max > range.max
				puts "out of upper limit #{range.max} < #{e}"
				ans = false
			elsif e.min < range.min
				puts "out of lower limit #{range.min} > #{e}"
				ans = false
			end		
		}
		ans
	end


	def look
		case self
		when Array
			self.map{|e| Array === e ? e.look : e.ar}
		when nil
			nil
		else
			self.ar
		end
	end

	
	def vtotal
		self.look.flatten.inject(0){|s,e| Numeric === e ? s+e : s}
	end

end