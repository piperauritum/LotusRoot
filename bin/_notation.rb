class Event
	attr_accessor :el, :du

	def initialize(e, d)
		@el, @du = e, d		# element, duration
	end

	def ar
		[@el, @du]
	end
end


module Notation

	## Pitch

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


	## Duration
	def tuplet_num_to_array(tpl, beat=1)
		if Array === tpl
			tpl
		else
			if (tpl*beat)%1==0
				numer = (tpl*beat).to_i
				denom = 2**Math.log2(numer).to_i
				unit_dur = Rational(1, denom)*beat
				[numer, denom, unit_dur]	# [3, 2, 1/2r] => \tuplet 3/2 {r8 r r }
			else
				raise "\nLo >> Tuplet #{tpl} could not divide by beat #{beat}.\n"
			end
		end
	end
	
=begin
	def convert_tuplet(tp)
		num, total = tp
			# [numerator, total duration]
			# [5, 1] => [5, 4, (1/4)]
		denom = 2**Math.log2(num).to_i
		[tp[0], denom, Rational(total, denom)]
	end
=end

	# Hash table of duration and note value in tuplet
	def note_value(tpl)
		rto_nu, rto_de, unit_nt = tuplet_num_to_array(tpl)

		duple_note = [*-6..2].map{|e|
			x = 2**e
			[x, "#{(4/x).to_i}"]
		}

		dotted_note = [*-6..0].map{|e|
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


	def note_value_dot(tpl)
		x = note_value(tpl)
		y = note_value(64).select{|k,v|
			k%(3/64r)==0 && x[k]!=nil
		}
		y=={} ? nil : y
	end


	def dot?
		cond = [
			Array===self,
			Math.log2(self[0])%1==0,
			self[1]%3==0,
			note_value_dot(self)!=nil
		]
		cond.inject(true){|s,e| s && e}
	end


	def nval_pos(measure)
		if Fixnum===measure
			meas = [[measure], 1]
		else
			meas = measure.deepcopy
		end

		meas[0].each.with_index{|e,i|
			if Math.log2(e)%1==0 && e>1
				meas[0][i] = [2]*(e/2)
			elsif e%3==0
				meas[0][i] = [3]*(e/3)
			elsif e>3
				meas[0][i] = [2]*(e/2-1)+[e%2+2]
			end
			meas[0].flatten!
		}

		nvpo = {
			2 => [
			#	[8, [0]],
			#	[6, [0]],
			#	[4, [0]],
			#	[3, [0]],
				[2, [0]],
				[1.5r, [0, 0.5]],
			],
			3 => [
			#	[8, [0]],
			#	[6, [0]],
			#	[4, [0]],
				[3, [0]],
				[2, [0, 1]],
				[1.5r, [0, 0.5, 3/4r]],
				[1, [*0..4].map{|e| e/2.0}],
			],
		}
		
		tm = 0
		ary = []
		meas[0].each{|m|
			if nvpo[m]!=nil
				nvpo[m].each{|nval, pos|
					pos.each{|po|
						ary << [nval, po+tm].map{|e|
							Rational(e)*meas[1]
						}
					}
				}
				tm += m
			end
		}
		ary
	end


	## Event

	# Look inside of event structure
	def lookinside(type)
		sel = ->(x){
			case type
			when :ar; x.ar
			when :el; x.el
			when :du; x.du
			end
		}
		case self
		when Array
			self.map{|e|
				case e
				when Array
					e.lookinside(type)
				when Event
					sel.call(e)
				else
					e
				end
			}
		when nil
			nil
		else
			sel.call(self)
		end
	end

	def look
		self.lookinside(:ar)
	end

	def elook
		self.lookinside(:el)
	end

	def dlook
		self.lookinside(:du)
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