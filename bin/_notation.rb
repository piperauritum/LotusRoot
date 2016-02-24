﻿class Event
	attr_accessor :el, :du
	
	def initialize(e, d)
		@el, @du = e, d		# element, duration
	end
	
	def ar
		[@el, @du]
	end
end


module Notation

	# Hash table of duration and note value in tuplet
	def note_value(tpl)

		if Array === tpl
			if tpl.size==2
				rto_nu = tpl[0]
				rto_de = 2**Math.log2(tpl[0]).to_i
				unit_nt = Rational(2*tpl[1], rto_de)
					# [amount of notes, unit duration]
					# [5, 1/4r] => \tuplet 5/4 {r16 r r r r } 
			else
				rto_nu, rto_de, unit_nt = tpl
					# [numerator, denominator, unit duration]
					# [3, 2, 1/2r] => \tuplet 3/2 {r8 r r }
			end
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
			unit_du = unit_nt
			nt = notation.select{|dur, note|	
				dur>=unit_du && (dur<=unit_du*rto_nu || Math.log2(rto_nu)%1==0)
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

	# Look inside of event structure
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


	def elook
		case self
		when Array
			self.map{|e| Array === e ? e.elook : e.el}
		when nil
			nil
		else
			self.el
		end
	end

	
	# Total duration of event structure
	def dtotal
		if self!=[]
			self.look.flatten.inject(0){|s,e| Numeric === e ? s+e : s}
		else
			0
		end
	end

end