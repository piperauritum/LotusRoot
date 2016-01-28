require_relative '_override'
require_relative '_notation'

class DataProcess
	include Notation

	def initialize(_tpl)
		@tpl = _tpl
	end
	
	def unfold_element(dur, elem)
		# dur = [4]; elem = ["@"]
		# => ["@", "=", "=", "="]

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
	
	
	def make_tuplet(ary, tpl=0)
		# ary = ["@", "=", "=", "="]; tpl = [6]
		# => [["@", "=", "=", "=", "r!", "r!"]]
		
		new_tpl = []

		if Array === tpl
			arx = []
			idx = 0
			while ary.size>0
				tp = tpl.on(idx)
				tp = tp[0] if Array===tp
				if ary.size>tp
					arx << ary.slice!(0, tp)
				else
					ay = ary.slice!(0, ary.size)
					ay += Array.new(tp-ay.size, "r!")
					arx << ay
				end
				new_tpl << tpl.on(idx)
				idx += 1
			end
			ary = arx.dup
			
		elsif tpl>0
			tp = tpl
			tp = tp[0] if Array===tp
			(tp-ary.size%tp).times{ ary << "r!" } if ary.size%tp>0
			ary = ary.each_slice(tp).to_a
			new_tpl = [tpl]*ary.size
		end
		
		@tpl = new_tpl.dup
		ary
	end

	
	def delete_syncop(seq)
		seq.map{|e|
			if e[0]=="=" && e-["="]!=[]
				re = true
				e.map{|f|
					case f
					when /@/
						re = false
						f
					when "="
						re ? "r!" : f
					else
						f
					end
				}
			else
				e
			end 
		}
	end
	
	
	def quad_event(tuple, past, tick)
		# ["@", "@", "=", "=", "r!", "r!"]
		# => [[["@", (8/3)], ["@", (8/1)]], [["r!", (16/3)]]]

		quad, evt = [], nil
		sliced = tuple.each_slice(4).to_a
		sliced.each{|sl|
			qa = []
			sl.each_with_index{|el, i|
				if i==0
					evt = Event.new(el, tick)
				else
					n_rest = %w(r! s!).map{|e|
						xelm = !(past=~/#{e}/) && el=~/#{e}/
						xelm ? 1:0
					}.sigma>0					
					c_tie = [el]-%w(= =:)==[]					
					c_trem = past=~/%/ && el=~/%/ && !(el=~/%%/)					
					c_rest = %w(r! s!).map{|e| past=~/#{e}/ && el=~/#{e}/ ? 1:0 }.sigma>0
	
					if el=~/(@|%%|rrr|sss)/ ||n_rest					
						qa << evt
						evt = Event.new(el, tick)
					elsif c_tie || c_trem || c_rest					
						evt.va += tick
					end
				end
				past = el
			}
			qa << evt
			quad << qa
		}
		[quad, past]
	end

	
	def connect_quad(quad, dv)		
		# [[["@", (8/1)], ["r!", (8/3)]], [["r!", (16/3)]]]
		# => [["@", (8/1)], ["r!", (8/1)]]
	
		qv = quad.vtotal	
		while 0
			id = 0
			cd = false
			
			while id<quad.size
				fo, la = quad[id], quad[id+1]
				
				if la!=nil
					fol, laf = fo.last, la.first
					cond = [
						(fol.el=~/@/ || fol.el=='+' || [fol.el]-%w(= =:)==[]) && [laf.el]-%w(= =:)==[],
						fol.el=~/r!/ && laf.el=~/r!/,
						fol.el=~/s!/ && laf.el=~/s!/,
						fol.el=~/%/ && laf.el=~/%/ && !(laf.el=~/%%/),
					]
					nval = note_value(dv)[fol.va + laf.va]

					if cond.inject(false){|s,e| s||e} && nval!=nil
						fol.va += laf.va
						la.shift
						quad.delete_if{|e| e==[]}
						cd = cd||true
					end
				end
				id += 1
			end
			break if cd == false
		end
		
		raise "invalid value data" if qv!=quad.vtotal
		quad.flatten!
	end
	
	
	def mold_bar(ary_beat, measure)	
		# Grouping beats into measure
		# [[["@", (16/1)]], [["=", (16/1)]], [["=", (32/3)], ["r!", (16/3)]]]
		# => [[[["@", (16/1)]], [["=", (8/1)]]], [[["=", (32/3)], ["r!", (16/3)]], [["r!", (8/1)]]]]
		# Fit beat into measure, Compress duration on half-beats, Fill bar(s) by rests.

		idx = 0
		bt_sum = 0
		bar, bars = [], []
		new_tpl = @tpl.dup

		# split into bar
		while ary_beat.size>0
			meas = measure.on(idx)

			if Fixnum === meas		# time N/4
				a_dur = ary_beat.vtotal/PPQN
### wrong ###			
				if a_dur < meas
					rest = meas-a_dur
					r_dur = Rational(1, rest.denominator)
					r_num = (rest/r_dur).to_i
					ary_beat << [Event.new("r!", r_dur*PPQN)]*r_num
					new_tpl << [r_num, r_num, r_dur]
				end

				while bt_sum < meas*PPQN && ary_beat.size>0
					bar << ary_beat.slice!(0)
					bt_sum = bar.vtotal
				end
			
				bars << bar
				bar = []
				bt_sum -= meas*PPQN
				
			else					# time N/8
				num = meas[0].size
				if ary_beat.size<num
					(num-ary_beat.size).times{
						ary_beat << [Event.new("r!", Rational(PPQN))]
					}
				end
				ar = ary_beat.slice!(0, num)
				ar = ar.map.with_index{|e,i|		# compress dur
					e.map{|f| Event.new(f.el, (f.va*Rational(meas[0][i], meas[1])))}
				}
				bars << ar
			end
	
			idx += 1
		end
=begin
		# fit into final-bar
		if @finalBar!=nil
			if @finalBar>bars.size
				(@finalBar-bars.size).times{
					meas = measure.on(idx)
					ar = []
					if Fixnum === meas
						meas.times{
							ar << [Event.new("r!", Rational(PPQN))]
							new_tpl << [1]*3
						}
					else
						ar = []
						meas[0].each{|e|
							ar << [Event.new("r!", Rational(PPQN*e, meas[1]))]
							new_tpl << [1, 1, Rational(PPQN*e, meas[1])]
						}
					end
					bars << ar
					idx += 1
				}
			else
				bars = bars[0..@finalBar-1]
			end
		end
=end
		@tpl = new_tpl.dup
		bars
	end


	def connect_beat(ary_beat, measure)
		# [[["@", (32/3)], ["@", (16/3)]], [["=", (16/1)]], [["=", (16/1)]], [["=", (16/3)], ["@", (32/3)]]]
		# => [[[["@", (32/3)], ["@", (16/3)]], [["=", (32/1)]], [["=", (16/3)], ["@", (32/3)]]]]

		bars = mold_bar(ary_beat, measure)
		bars.each{|bar|
			bv = bar.vtotal

			while 0
				id = 0
				cd = false
				
				while id<bar.size
					fo, la = bar[id], bar[id+1]
					
					if la!=nil
						fol, laf = fo.last, la.first
			
						nv = fol.va + laf.va
						matchValue = note_value(16)[nv]!=nil
						matchValue = matchValue && Math.log2(nv)%1==0 if id%2==1	# avoid dotted value at off-beat
						duples = [1/2r,1,2].map{|e| Rational(PPQN)*e}
						matchDup = [fol.va]-duples==[] && [laf.va]-duples==[]
						homoElem = [laf.el]-%w(= =:)==[] ||
							((fo.size==1 || la.size==1) && fol.el=~/%/ && laf.el=~/%/ && !(laf.el=~/%%/)) ||
							(laf.el=="r!" && fol.el=~/r!/) ||
							(laf.el=="s!" && fol.el=~/s!/)
						tup = ->(x){x.map(&:va).map{|e| e/PPQN}.map(&:denominator).max}
						homoPlet = Math.log2(tup.(fo))%1==0 && Math.log2(tup.(la))%1==0
					
						if matchValue && matchDup && homoElem && homoPlet
							fol.va += laf.va
							la.shift
							bar.delete_if{|e| e==[]}
							cd = cd||true
						end
					end
					id += 1					
				end

				break if cd == false
			end	

			raise "invalid value data" if bv!=bar.vtotal
		}
	end

end