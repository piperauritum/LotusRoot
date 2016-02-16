require_relative '_override'
require_relative '_notation'

class DataProcess
	include Notation

	def initialize(_tpl)
		@tpl = _tpl
	end
	
	def unfold_element(dur, elem)
		# dur = [4]; elem = ["@"]
		# =>  ary = ["@", "=", "=", "="]

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
		# ary = ["@", "=", "=", "@", "=", "="]; tpl = [2, 3]
		# =>  ary = [[["@", (1/2)], ["=", (1/2)]], [["=", (1/3)], ["@", (1/3)], ["=", (1/3)]], [["=", (1/2)], ["r!", (1/2)]]]
		# =>  tpl = [2, 3, 2]
		
		new_tpl = []

		if Array === tpl
			arx = []
			idx = 0
			while ary.size>0
				tp = tpl.on(idx)
				if Array===tp
					len = tp[0]
					if tp.size==2
						tick = Rational(tp[0]*tp[1], tp[0])
					else
						tick = Rational(tp[2]*tp[1], tp[0])
					end
				else
					len = tp
					tick = Rational(1, tp)
				end
				
				if ary.size>len
					ay = ary.slice!(0, len)					
				else
					ay = ary.slice!(0, ary.size)
					ay += Array.new(len-ay.size, "r!")
				end
				ay = ay.map{|e| Event.new(e, tick)}
				arx << ay
				new_tpl << tpl.on(idx)
				idx += 1
			end
			ary = arx.dup
			
		elsif tpl>0
			tp = tpl.on(idx)
			if Array===tp
				len = tp[0]
				tick = Rational(tp[2]*tp[1], tp[0])
			else
				len = tp
				tick = Rational(1, tp)
			end
			
			(len-ary.size%len).times{ ary << "r!" } if ary.size%len>0
			ary = ary.map{|e| Event.new(e, tick)}
			ary = ary.each_slice(len).to_a
			new_tpl = [tpl]*ary.size
		end

		
		@tpl = new_tpl.dup
		ary
	end

	
	def delete_syncop(seq)
		# seq.map{|e| e.look.transpose[0]} = [["@", "="], ["=", "@", "="], ["=", "r!"]]
		# =>  seq.map{|e| e.look.transpose[0]} = [["@", "="], ["r!", "@", "="], ["r!", "r!"]]

		seq.map{|e|
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
	
	
	def quad_event(tuple, past, tick)
		# tuple = [["@", (1/6)], ["@", (1/6)], ["=", (1/6)], ["=", (1/6)], ["r!", (1/6)], ["r!", (1/6)]]
		# =>  quad = [[["@", (1/6)], ["@", (1/2)]], [["r!", (1/3)]]]

		quad, evt = [], nil
		sliced = tuple.each_slice(4).to_a
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
		}
		[quad, past]
	end

	
	def connect_quad(quad, dv)		
		# quad = [[["@", (1/6)], ["@", (1/3)], ["r!", (1/6)]], [["r!", (1/3)]]]
		# =>  quad = [["@", (1/6)], ["@", (1/3)], ["r!", (1/2)]]

		qv = quad.dtotal	
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
					nval = note_value(dv)[fol.du + laf.du]

					if cond.inject(false){|s,e| s||e} && nval!=nil
						fol.du += laf.du
						la.shift
						quad.delete_if{|e| e==[]}
						cd = cd||true
					end
				end
				id += 1
			end
			break if cd == false
		end
		
		raise "invalid value data" if qv!=quad.dtotal
		quad.flatten!
	end
	
	
	def barr(ary_beat, measure)		
		meas_id = 0
		bars = []
		bar_residue = 0

		# split into bar
		while ary_beat.size>0 || bar_residue>0
			meas = measure.on(meas_id)
			meas = Rational(meas[0].sigma, meas[1]) if Array===meas

			if ary_beat.dtotal<meas
				filler = []
				tpl_add = []
				len = ary_beat.dtotal+filler.dtotal+bar_residue
				gap = meas-len
				while gap>0						
					tk = note_value(16).select{|e| e<=gap}.max[0]
					filler << [Event.new("r!", tk)]
					tpl_add << [1, 1, tk]
					gap -= tk
				end
				filler.reverse!
				tpl_add.reverse!
				ary_beat += filler
				@tpl += tpl_add
			end
				
			bar = []
			while bar.dtotal+bar_residue<meas
				bar << ary_beat.shift
			end
	
			bar_residue = bar.dtotal+bar_residue-meas
			bars << bar

	
			meas_id += 1
		end

		bars
	end
	
	
	def mold_bar(ary_beat, measure)		
		# [[["@", (16/1)]], [["=", (16/1)]], [["=", (32/3)], ["r!", (16/3)]]]
		# => [[[["@", (16/1)]], [["=", (8/1)]]], [[["=", (32/3)], ["r!", (16/3)]], [["r!", (8/1)]]]]
		# Fit beat into measure, Compress duration on half-beats, Fill bar(s) by rests.

		idx = 0
		bars = []
		
		# split into bar
		while ary_beat.size>0
			meas = measure.on(idx)

			if Fixnum === meas		# time N/4
				if ary_beat.size<meas
					(meas-ary_beat.size).times{
						ary_beat << [Event.new("r!", 1)]		# rest filling
					}
				end
				bars << ary_beat.slice!(0, meas)
				
			else					# time N/8
				num = meas[0].size
				if ary_beat.size<num
					(num-ary_beat.size).times{
						ary_beat << [Event.new("r!", 1)]
					}
				end
				ar = ary_beat.slice!(0, num)
				ar = ar.map.with_index{|e,i|		# compress dur
					e.map{|f| Event.new(f.el, (f.du*Rational(meas[0][i], meas[1])))}
				}
				bars << ar
			end
	
			idx += 1
		end

		# fit into final-bar
		if @finalBar!=nil
			if @finalBar>bars.size
				(@finalBar-bars.size).times{
					meas = measure.on(idx)
					ar = []
					if Fixnum === meas
						meas.times{
							ar << [Event.new("r!", 1)]
						}
					else
						ar = []
						meas[0].each{|e|
							ar << [Event.new("r!", Rational(e, meas[1]))]
						}
					end
					bars << ar
					idx += 1
				}
			else
				bars = bars[0..@finalBar-1]
			end
		end

		bars
	end


	def connect_beat(ary_beat, measure)
		# [[["@", (32/3)], ["@", (16/3)]], [["=", (16/1)]], [["=", (16/1)]], [["=", (16/3)], ["@", (32/3)]]]
		# => [[[["@", (32/3)], ["@", (16/3)]], [["=", (32/1)]], [["=", (16/3)], ["@", (32/3)]]]]

	#	bars = mold_bar(ary_beat, measure)
		bars = barr(ary_beat, measure)

		bars.each{|bar|
			bv = bar.dtotal

			while 0
				id = 0
				cd = false
				
				while id<bar.size
					fo, la = bar[id], bar[id+1]
					
					if la!=nil
						fol, laf = fo.last, la.first
			
						nv = fol.du + laf.du
						matchValue = note_value(16)[nv]!=nil
						matchValue = matchValue && Math.log2(nv)%1==0 if id%2==1	# avoid dotted value at off-beat
						duples = [1/2r,1,2].map{|e| e}
						matchDup = [fol.du]-duples==[] && [laf.du]-duples==[]
						homoElem = [laf.el]-%w(= =:)==[] ||
							((fo.size==1 || la.size==1) && fol.el=~/%/ && laf.el=~/%/ && !(laf.el=~/%%/)) ||
							(laf.el=="r!" && fol.el=~/r!/) ||
							(laf.el=="s!" && fol.el=~/s!/)
						tup = ->(x){x.map(&:du).map{|e| e}.map(&:denominator).max}
						homoPlet = Math.log2(tup.(fo))%1==0 && Math.log2(tup.(la))%1==0
					
						if matchValue && matchDup && homoElem && homoPlet
							fol.du += laf.du
							la.shift
							bar.delete_if{|e| e==[]}
							cd = cd||true
						end
					end
					id += 1					
				end

				break if cd == false
			end	

			raise "invalid value data" if bv!=bar.dtotal
		}
	end

end