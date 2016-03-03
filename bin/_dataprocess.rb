﻿require_relative '_override'
require_relative '_notation'

class DataProcess
	include Notation

	def initialize(_tpl)
		@tpl = _tpl
	end

	# dur = [4]; elem = ["@"]
	# =>  ["@", "=", "=", "="]
	def unfold_element(dur, elem)
		ary = []
		elem.zip(dur).each{|el, du|
			if du>0
				case el
				when /@/			# attack
					ary << el
					if el=~/@:/		# tremolo
						(du-1).times{ ary << "=:" }
					else
						(du-1).times{ ary << "=" }
					end

				when /(r!|s!|rrr|sss)/	# rest, spacer rest
					du.times{|i| i==0 ? ary << el : ary << $1}

				when /%/			# two-notes tremolo
					du.times{|n|
						if n==0
							ary << el.sub("%", "%%")
						else
							ary << el.scan(/%\d+/)[0] + el.scan(/\[.+\]/)[0]
						end
					}

				when /=/			# tie
					du.times{ ary << el }

				when Array			# staccato
					eel, edu = el
					if edu>0
						ary << eel
						if eel=~/@:/
							([edu, du].min-1).times{ ary << "=:" }
						else
							([edu, du].min-1).times{ ary << "=" }
						end
					end
					(du-edu).times{ ary << "r!" }
				end
			end
		}
		ary
	end


	# [3, [[2, 1], 2]] => [1, 1, 1, (1/1), (1/2)]
	def unfold_measure(measure)
		measure.map{|e|
			if Array===e
				e[0].map{|f| Rational(f, e[1])}
			else
				[1]*e
			end
		}.flatten
	end


=begin
	ary = ["@", "=", "=", "@", "=", "="]
	tpl = [2, 3]
=>	ary = [[
				["@", (1/2)], ["=", (1/2)]
			], [
				["=", (1/3)], ["@", (1/3)], ["=", (1/3)]
			], [
				["=", (1/2)], ["r!", (1/2)]
			]]
=>	tpl = [2, 3, 2]
=end
	def make_tuplet(ary, tpl, measure)
		meas = unfold_measure(measure)
		new_tpl = []
		arx = []
		idx = 0

		while ary.size>0
			tp = tpl.on(idx)
			me = meas.on(idx)
			if Fixnum===tp && tp<me.denominator
				raise "\nLo >> Unit length of tuplet (#{Rational(1,tp)}) is longer than beat length of measure (#{me}).\n"
			end

			# Change tuplet number for fractional beat
			# tp = 4; me = (1/2)
			# => [2, 2, (1/4)]
			if Fixnum===tp && Math.log2(tp)%1==0 && Rational===me
				tp = [me*tp, me*tp, Rational(1,tp)]
				new_tpl << tp
			else
				new_tpl << tpl.on(idx)
			end

			if Array===tp
				if tp.size==2
					tp = convert_tuplet(tp)
				end
				tick = Rational(tp[2]*tp[1], tp[0])
			else
				tick = Rational(1, tp)
			end

			len = tp
			len = tp[0] if Array===tp

			if ary.size>len
				ay = ary.slice!(0, len)
			else
				ay = ary.slice!(0, ary.size)
				ay += Array.new(len-ay.size, "r!")
			end

			# Simplify tuplet
			tie_only = ay-%w(= =:)==[]
			atk_tie = ay[0]=~/@/ && ay[1..-1]-%w(= =:)==[]
			if tie_only || atk_tie
				du = tick*len
				tick = Rational(1, du.denominator)
				len = du.numerator
				ay = [ay[0]] + [ay[1]]*(len-1)
				new_tpl[-1] = [len, len, tick]
			end

			ay = ay.map{|e| Event.new(e, tick)}
			arx << ay
			idx += 1
		end

		[arx.dup, new_tpl.dup]
	end


	# [["@", "="], ["=", "@", "="], ["=", "r!"]]
	# =>  [["@", "="], ["r!", "@", "="], ["r!", "r!"]]
	def delete_suspension(ary)
		ary.map{|e|
			if e[0].el=="=" && e.look.transpose[0]-["="]!=[]
				re = true
				e.map{|f|
					case f.el
					when /@/
						re = false
						f
					when "="
						re ? Event.new("r!", f.du) : f
					else
						f
					end
				}
			else
				e
			end 
		}
	end


=begin
	tuple =	[["@", (1/6)], ["@", (1/6)], ["=", (1/6)], ["=", (1/6)], ["r!", (1/6)], ["r!", (1/6)]]
=>	quad = [[
				["@", (1/6)], ["@", (1/2)]
			], [
				["r!", (1/3)]
			]]
=end
	def tuple_to_quad(tuple, past, tick)
		quad, evt = [], nil
		@dotDuplet ? s=2 : s=4
		sliced = tuple.each_slice(s).to_a

		sliced.each{|sl|
			qa = []
			sl.each_with_index{|ev, i|
				if i==0
					evt = ev
				else
					n_rest = %w(r! s!).map{|e|
						xelm = !(past=~/#{e}/) && ev.el=~/#{e}/
						xelm ? 1:0
					}.sigma>0
					c_tie = [ev.el]-%w(= =:)==[]
					c_trem = past=~/%/ && ev.el=~/%/ && !(ev.el=~/%%/)
					c_rest = %w(r! s!).map{|e| past=~/#{e}/ && ev.el=~/#{e}/ ? 1:0 }.sigma>0

					if ev.el=~/(@|%%|rrr|sss)/ ||n_rest
						qa << evt
						evt = ev
					elsif c_tie || c_trem || c_rest
						evt.du += tick
					end
				end
				past = ev.el
			}
			qa << evt
			quad << qa
#	puts "#{sl.look} => #{qa.look}"
		}
		[quad, past]
	end


=begin
	[[
		["@", (1/6)], ["@", (1/3)], ["r!", (1/6)]
	], [
		["r!", (1/3)]
	]]

=>	[["@", (1/6)], ["@", (1/3)], ["r!", (1/2)]]
=end
	def connect_quad(quad, tp)
		qv = quad.dtotal
		tick = Rational(tp[2]*tp[1], tp[0])
		meas = [[tp[0]], tick]
		np = nval_pos(meas)
		
		while 0
			id = 0
			tm = 0
			cd = false

			while id<quad.size
				fo, la = quad[id], quad[id+1]

				if la!=nil
					fol, laf = fo.last, la.first
					nv = fol.du + laf.du

					if @dotDuplet && tp.dot?
						nval = note_value_dot(tp)[nv]
					else
						nval = note_value(tp)[nv]
					end
					
					unless np.inject(false){|s,e| (nv==e[0] && tm==e[1]) || s}
						nval = nil
					end

					cond = [
						(fol.el=~/@/ || fol.el=='+' || [fol.el]-%w(= =:)==[]) && [laf.el]-%w(= =:)==[],
						fol.el=~/r!/ && laf.el=~/r!/,
						fol.el=~/s!/ && laf.el=~/s!/,
						fol.el=~/%/ && laf.el=~/%/ && !(laf.el=~/%%/),
					]
					if cond.inject(false){|s,e| s||e} && nval!=nil
						fol.du += laf.du
						la.shift
						quad.delete_if{|e| e==[]}
						cd = cd||true
					end

					tm += fo.dtotal
				end
				id += 1
			end
			break if cd == false
		end

		raise "\nLo >> Invalid value data\n" if qv!=quad.dtotal
		quad.flatten!
	end

	# Split into bar
	def make_bar(tuples, measure, final_bar)
		meas_id = 0
		bars = []
		bar_residue = 0

		while tuples.size>0 || bar_residue>0
			meas = measure.on(meas_id)
			meas = Rational(meas[0].sigma, meas[1]) if Array===meas

			if tuples.dtotal<meas
				filler = []
				tpl_add = []
				len = tuples.dtotal+filler.dtotal+bar_residue
				gap = meas-len

				while gap>0
					tk = note_value(16).select{|e| e<=gap}.max[0]
					filler << [Event.new("r!", tk)]
					tpl_add << [1, 1, tk]
					gap -= tk
				end

				filler.reverse!
				tpl_add.reverse!
				tuples += filler
				@tpl += tpl_add
			end

			bar = []
			while bar.dtotal+bar_residue<meas
				bar << tuples.shift
			end

			bar_residue = bar.dtotal+bar_residue-meas
			bars << bar
			meas_id += 1
		end

		bars = finish_bar(bars, measure, meas_id, final_bar)
		bars
	end


	# Add rests or cut bars for fit into final_bar length
	def finish_bar(bars, measure, meas_id, final_bar)
		if final_bar!=nil
			if final_bar>bars.size
				(final_bar-bars.size).times{
					meas = measure.on(meas_id)
					ar = []
					if Fixnum === meas
						meas.times{
							ar << [Event.new("r!", 1r)]
						}
					else
						meas[0].each{|e|
							ar << [Event.new("r!", Rational(e, meas[1]))]
						}
					end
					bars << ar
					meas_id += 1
				}
			else
				bars = bars[0..final_bar-1]
			end
		end
		bars
	end


	def connect_beat(bars, measure, tpl)

		# Associate tuplet and tuplet-number
		tx = 0
		barr = bars.map{|e|
			e.map{|f|
				t = tpl[tx]
				t = convert_tuplet(t) if t.size==2
				t = [1, 1, f[0].du] if f.size==1 && Math.log(f[0].du).abs%1==0
				z = [f, t]
				tx += 1
				z
			}
		}

		barr.each.with_index{|bar, idx|
			bv = bar.map{|e| e[0]}.dtotal
			meas = measure.on(idx)

			if (Array===meas && Rational(meas[0].sigma, meas[1])!=bv) || (Fixnum===meas && meas!=bv)
				raise "\nLo >> total duration of bar (#{bv}) is different from the time signature (#{meas})\n"
			end

			while 0
				id = 0
				tm = 0
				cd = false

				while id<bar.size
					fo, la = bar[id], bar[id+1]

					if la!=nil
						fo_e, fo_t = fo
						la_e, la_t = la
						fol, laf = fo_e.last, la_e.first
						tm += fo_e[0..-2].dtotal if fo_e.size>1
						nv = fol.du + laf.du
						matchValue = note_value(16)[nv]!=nil

						if matchValue
							if Fixnum===meas
								np = nval_pos(meas)
								matchValue = np.inject(false){|s,e| (nv==e[0] && tm==e[1]) || s}

=begin
								conds = ->(co){
									co.inject(false){|s,e| tm%e[0]==e[1] || s}
								}
								cc = {
									2 => {
										1r => [[2, 0], [2, 0.5], [2, 1]],
										1.5r => [[2, 0], [2, 0.5]],
										2r => [[1, 0]],
										3r => [[1, 0]],
									},
									3 => {
										1r => [[2, 0], [2, 0.5], [2, 1]],
										1.5r => [[3, 0], [3, 0.5], [3, 1]],
										2r => [[1, 0]],
									}
								}
								if meas%3==0
									co = cc[3][nv.to_r]
									matchValue = conds.call(co) if co!=nil
								elsif meas%2==0
									co = cc[2][nv.to_r]
									matchValue = conds.call(co) if co!=nil
								end
=end
							else
=begin
								co = []
								cc = {
									2 => [
										[2, [0]],
										[1.5r, [0, 0.5]],
									],
									3 => [
										[3, [0]],
										[2, [0, 1]],
										[1.5r, [0, 0.5, 3/4r]],
										[1, [*0..4].map{|e| e/2.0}],
									],
								}
								te = 0
								meas[0].each{|me|
									if cc[me]!=nil
										cc[me].each{|nval, pos|
											pos.each{|po|
												co << [nval, po+te].map{|e| Rational(e, meas[1])}
											}
										}
										te += me
									end
								}
=end

								np = nval_pos(meas)
								matchValue = np.inject(false){|s,e| (nv==e[0] && tm==e[1]) || s}

							end
						end

						if @dotDuplet && fo_t.dot? && la_t.dot?
							nval = [1,2,3,4,6,8].map{|e| Rational(e*3,8)}
						else
							nval = [1,2,3,4,6,8].map{|e| Rational(e,2)}
						end

						matchDup = [fol.du]-nval==[] && [laf.du]-nval==[]
						cond = [
							[laf.el]-%w(= =:)==[],
							(fo.size==1 || la.size==1) && fol.el=~/%/ && laf.el=~/%/ && !(laf.el=~/%%/),
							laf.el=="r!" && fol.el=~/r!/,
							laf.el=="s!" && fol.el=~/s!/,
						]
						homoElem = cond.inject(false){|s,e| s||e}
						tup = ->(x){x[0].map{|e| e.du}.map(&:denominator).max}
						homoPlet = Math.log2(tup.(fo))%1==0 && Math.log2(tup.(la))%1==0
						if matchValue && matchDup && homoElem && homoPlet
							fol.du += laf.du
							la_e.shift
							fo_t = 16
							bar.delete_if{|e| e[0]==[]}
							cd = cd||true
						end

						tm += fo_e[-1].du
					end
					id += 1
				end
				break if cd == false
			end

			raise "\nLo >> invalid value data\n" if bv!= bar.map{|e| e[0]}.dtotal
		}
		b = barr.map{|e| e.map{|f| f[0]}}
		t = barr.inject([]){|s,e| s += e.map{|f| f[1]}}
		[b, t]
	end

end