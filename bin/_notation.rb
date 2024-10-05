require_relative '_class'

module Notation

### Pitch ###

	def note_name(pc, acc = 0, alt = nil)
		if Complex === pc
			acc = pc.imag
			pc = pc.real
		end

		diatonic = %w(c d e f g a b)

		chromatic = [[2, 6], [0, 3]].map.with_index{|x, i|
			diatonic.map.with_index{|n, deg|
				if [deg] - x == []
					n
				else
					[[n, n + "is"], [n + "es", n]][i]
				end
			}.flatten
		}.at(acc % 2)

		if acc > 3
			enharmonic = [[2, 6, -1], [0, 3, 1]].map.with_index{|x, i|
				r = x.pop
				diatonic.map.with_index{|n, deg|
					if [deg] - x == []
						[n + "is", n + "es"][i]
					else
						[n + "isis", n + "eses"][i]
					end
				}.rotate(r)
			}.at(acc % 2)

			enharmonic = diatonic.zip(enharmonic).to_h

			chromatic = chromatic.map{|x|
				enharmonic.has_key?(x) ? enharmonic[x] : x
			}
		end

		if acc < 2
			qtone = chromatic.map{|n|
				[[n, n + "ih"], [n + "eh", n]][acc % 2]
			}.flatten
		else
			qtone = chromatic.map.with_index{|n, i|
				case i
				when 0, 2, 5, 7, 9
					[n + "eh", n, n + "ih"]
				when 4, 11
					[n + "eh", n]
				else
					n
				end
			}.flatten
		end

		qtone = qtone.rotate(qtone.index(chromatic[0]))

		etone = qtone.map.with_index{|n, i|
			if i % 2 == 0
				[n + "e", n, n + "i"]
			else
				n
			end
		}.flatten

		etone = etone.rotate(etone.index(chromatic[0]))

		if alt != nil
			rep = alt.transpose[0]
			rep = rep.max / 12 + 1
			etone = etone * rep
			alt.each{|e|
				pitch, nname = e
				etone[pitch * 4] = nname
			}
		end

		if acc < 4
			na = etone.on(pc * 4)
		else
			na = chromatic.on(pc)
		end

		otv = (pc / 12.0).floor

		case na
		when /ce/
			otv += 1
		when /bis/
			otv -= 1
		end
		otv.abs.times{
			pc > 0 ? na += "'" : na += ","
		}
		na
	end


	def auto_accmode(chord, mode, func)
		mo = mode

		## Avoids imperfect unison in chromatic chords
=begin
		## Previous method
		am = chord.map{|x| x%12}
		[0,2,5,7,9].each{|e|
			mo = 1 if am.include?(e) && am.include?(e+1)
		}
		[2,4,7,9,11].each{|e|
			mo = 0 if am.include?(e) && am.include?(e-1)
		}
=end

		chord.each{|e|
			mo = 1 if chord.include?(e + 1) && [0, 2, 5, 7, 9].include?(e % 12)
			mo = 0 if chord.include?(e - 1) && [2, 4, 7, 9, 11].include?(e % 12)
		}

		## Aligns the degrees of dyads
		sel = ->(ary){
			ary.each{|e|
				[*0 .. 2].each.with_index{|a, i|
					if chord.min % 12 == a / 2.0 + e	# applies on quarter tones
						mo = [1, 2, 0][i]
					end
				}
			}
		}

		if chord.size == 2 && func > 0
			wht = [2, 2, 1, 2, 2, 2, 1].map.with_index{|e, i| [i] * e}.flatten
			itv = (chord.max - chord.min) % 12		# applies on chromatic intervals
			itv = itv.real if Complex === itv
			sft = [wht, wht.rotate(itv)].transpose.map{|x, y| (y - x) % 7}
			mnr = sft.uniq.sort{|x, y| sft.count(x) <=> sft.count(y)}[0]
			ary = sft.map.with_index{|e, i| e == mnr ? i : nil} - [nil]
			ary = [*0 .. 11] - ary if itv == 6
			sel.call(ary)
		end

		mo
	end


	def natural?(pc)
		[0, 2, 4, 5, 7, 9, 11].include?(pc % 12)
	end


	def pitch_shift(pch, sum)
		pch.add(sum)
	end


	def chk_range(pch, a, b)
		pcs = pch.map{|e| Array === e ? e : [e]} - [[nil]]
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


### Duration ###

	def tuplet_num_to_param(tpl, beat = 1)
		case tpl
		when TplParam
			tpl.ar.to_tpar
		when Array
			tpl.to_tpar
		when Integer
			if (tpl * beat) % 1 == 0
				numer = (tpl * beat).to_i
				unit_dur = Rational(numer, beat)
				unit_dur = Rational(1, 2 ** Math.log2(unit_dur.ceil).to_i)
				denom = beat / unit_dur
			else
				numer = tpl
				unit_dur = Rational(beat, numer)
				unit_dur = 2 ** (Math.log2(unit_dur).to_i)
				denom = beat / unit_dur

				if denom % 1 != 0
					if note_value(64)[Rational(beat, numer)] != nil
						unit_dur = Rational(beat, numer)
						numer = beat / unit_dur
						denom = beat / unit_dur
					else
						d = Rational(denom, denom.numerator)
						numer /= d
						denom /= d
						unit_dur *= d
					end
				end
			end

			numer = numer.to_i
			denom = denom.to_i
			[numer, denom, unit_dur].to_tpar
		end
	end


	def tpar_abbreviations(tpar)
		divisor = [*1 .. tpar.numer-1].reverse.select{|e| (tpar.numer.to_f / e) % 1 == 0}
		rto = Rational(tpar.denom, 2 ** Math.log2(tpar.numer).to_i)
		divisor.map{|num|
			den = 2 ** Math.log2(num).to_i * rto
			unit_dur = Rational(tpar.denom * tpar.unit, den)
			if den % 1 == 0
				[num, den.to_i, unit_dur].to_tpar
			else
				nil
			end
		} - [nil]
	end


	def note_value(tpl)
		tpp = tuplet_num_to_param(tpl)
		tpp.numer = tpp.numer.sum if Array === tpp.numer

		duple_note = [*-16 .. 2].map{|e|
			x = 2 ** e
			[x, "#{(4 / x).to_i}"]
		}

		dotted_note = [*-16 .. 0].map{|e|
			x = 2 ** e
			[Rational(x * 3), "#{(2 / x).to_i}."]
		}

		double_dotted_note = [*-16 .. -1].map{|e|
		  x = 2 ** e
		  [Rational(x * 7), "#{(1 / x).to_i} .. "]
		}

		notation = (duple_note + dotted_note + double_dotted_note).sort{|x, y| x[0] <=> y[0]}

		if tpp.numer == 0
			nil
		else
			unit_du = tpp.unit
			nt = notation.select{|dur, note|
				dur >= unit_du && (dur <= unit_du * tpp.numer || Math.log2(tpp.numer) % 1 == 0)
			}

			nt = nt.map{|dur, note|
				[Rational(tpp.denom, tpp.numer) * dur, note]
			}

			nt += notation.select{|dur, note|
				dur == tpp.denom * tpp.unit
			}.map{|dur, note|
				[Rational(dur), note]
			}

			Hash[*nt.uniq.flatten]
		end
	end


	def note_value_dot(tpl)
		x = note_value(tpl)
		y = note_value(64).select{|k, v|
			k % (3/64r) == 0 && x[k] != nil
		}
		y == {} ? nil : y
	end


	def allowed_positions(tp_ary, pos_table, notevalue)
		bt_struct, unit_num, unit_dur = tp_ary.ar
		tme = 0
		ary = []
		rto = Rational(unit_num * unit_dur, bt_struct.sum)
		bt_struct.each{|bt|
			nv = Rational(notevalue, rto)
			tbl = pos_table[bt]
			if tbl != nil
				sel = tbl.select{|k, v| k == nv}.values[0]
				if sel != nil
					ary += sel.map{|po|
						(po + tme) * rto
					}
				end
				tme += bt
			end
		}

		ary
	end


### Event Structure ###

	def lookInside(type)
		sel = ->(x){
			case type
			when :ar; x.ar
			when :el; x.el
			when :du; x.du
			when :cl; x.class
			end
		}
		case self
		when Array
			self.map{|e|
				case e
				when Array
					e.lookInside(type)
				when Event, Tuplet, TplParam, Bar
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
		self.lookInside(:ar)
	end

	def elook
		self.lookInside(:el)
	end

	def dlook
		self.lookInside(:du)
	end

	def clook
		self.lookInside(:cl)
	end

	def dtotal
		if self != []
			self.look.flatten.inject(0){|s, e| Numeric === e ? s + e : s}
		else
			0
		end
	end

end
