require_relative '_override'
require_relative '_notation'

class DataProcess
	include Notation


	def initialize(_tuplets)
		@tpl_param = _tuplets
	end


	def unfold_elements(dur, elm)
		elm.map.with_index{|el, i|
			du = dur.on(i)
			if du>0
				case el
				when /@:/	# tremolo
					[el]+["=:"]*(du-1)

				when /@=/	# repeat markup on tied notes
					fo = el.sub("=", "")
					fo = fo.gsub(/#A(.*?)A#/m, "\\1")	# markup head
					la = el.sub("@", "=")
					la = la.gsub(/#A.*?A#/m, "")
					[fo]+[la]*(du-1)

				when /@/	# attack
					[el]+["="]*(du-1)

				when /(r!|s!|rrr|sss)/	# rest, spacer rest
					[el]+[$1]*(du-1)

				when /%/	# two-notes tremolo
					head = el.sub("%", "%ATK")
					rept = el.scan(/%\d+/)[0] + el.scan(/\[.+\]/)[0]
					[head]+[rept]*(du-1)

				when /=/	# tie
					[el]*du

				when Array	# staccato
					stacc_el, stacc_du = el
					sdu = [stacc_du, du].min-1
					rest = ["r!"]*(du-stacc_du)

					if stacc_el=~/@:/
						[stacc_el]+["=:"]*sdu+rest
					else
						[stacc_el]+["="]*sdu+rest
					end

				end
			end
		}.flatten
	end


	def divide_metres_into_beats(metre)
		begin
			metre.map{|e|
				if Array===e
					e[0].map{|f| Rational(f*e[1])}
				else
					[1]*e
				end
			}.flatten
		rescue
			puts "LotusRoot >> .metre must be [Fixnum..] or [[[Fixnum..], Rational]..]"
			raise
		end	
	end


	def assemble_tuplets(ary, tpl, metre)
		new_tpl = []
		new_ary = []
		beats = divide_metres_into_beats(metre)
		idx = 0

		while ary.size>0
			begin
				tp = tpl.on(idx)
			rescue
				puts "LotusRoot >> Parameter of tuplet must be [Fixnum..] or [[Fixnum, Fixnum, Rational]..]"
				raise
			end

			bt = beats.on(idx)
			rept = 1

			if Fixnum===tp
				tp_a = tuplet_num_to_array(tp, bt)
				rto = Rational(tp_a[0], tp_a[1])
				if [
					tp_a[0]!=tp_a[1],
					tp_a[0]>tp,
					tp_a[0]!=rto.numerator,
					Rational(tp, rto.numerator)%1==0
				].all?
					if bt%1==0
						rept = tp_a[0]/tp
						tp_a = [tp, tp_a[1]/rept, tp_a[2]]
					else
						rept = tp_a[0]/rto.numerator
						tp_a = [rto.numerator, rto.denominator, tp_a[2]]
					end
				end
			else
				tp_a = tp
			end

			rept.times{
				begin
					len = tp_a[0]
					tick = Rational(tp_a[1]*tp_a[2], tp_a[0])
				rescue
					puts "LotusRoot >> Parameter of tuplet must be [Fixnum..] or [[Fixnum, Fixnum, Rational]..]"
					raise
				end

				if Fixnum===tp && tick.numerator>1
					len = tp
					tick *= Rational(tp_a[0], tp)
				end

				if note_value(tp_a)[tick]==nil
					msg = <<-EOS

LotusRoot >> Unexpected error
LotusRoot >> There is not notation of the duration (#{tick}) for tuplet (#{tp_a})
LotusRoot >> Beat: (#{bt})
LotusRoot >> #{note_value(tp_a)}
					EOS
					raise msg
				end

				# Cut tuplet out from array
				if ary.size>len
					ay = ary.slice!(0, len)
				else
					ay = ary.slice!(0, ary.size)
					ay += Array.new(len-ay.size, "r!")
				end

				# Simplify tuplet
				only_rest = ay-["r!"]==[]
				only_tie = ay-%w(= =:)==[]
				only_trem = ay.map{|e| !!(e=~/%\d+/)}.all?
				atk_tie = !!(ay[0]=~/@/) && ay[1..-1]-%w(= =:)==[]
				atk_trem = !!(ay[0]=~/%ATK/) && ay[1..-1].map{|e| !!(e=~/%\d+/)}.all?
				atk_mktie = (!!(ay[0]=~/@/) || !!(ay[0]=~/==/)) && ay[1..-1].map{|e| !!(e=~/==/)}.all?

				if [only_rest, only_tie, only_trem, atk_tie, atk_trem, atk_mktie].any?
					du = tick*len
					tick = Rational(1, du.denominator)
					len = du.numerator
					ay = [ay[0]] + [ay[1]]*(len-1)
					new_tpl << [len, len, tick]
				else
					if Fixnum===tp
						new_tpl << tp_a
					else
						new_tpl << tpl.on(idx)
					end
				end

				ay = ay.map{|e| Event.new(e, tick)}
				new_ary << ay
			}
			idx += 1
		end

		[new_ary.dup, new_tpl.dup]
	end


	def delete_ties_across_beats(ary)
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


	def subdivide_tuplet(tuple, past, tick, tp_a)
		quad, evt = [], nil
		t = tuple.size
		beats = [t]
		if @dotDuplet
			beats = [2]*(t/2)+[t%2]
		elsif t%3==0
			beats = [3]*(t/3)
		else
#			beats = [4]*(t/4)+[t%4]
			beats = [2]*(t/2)+[t%2]
		end
		beats -= [0]

		sliced = []
		beats.each{|e|
			sliced << tuple.shift(e)
		}

		sliced.each{|sl|
			qa = []
			sl.each_with_index{|ev, i|
				if i==0
					evt = ev
				else
					n_rest = %w(r! s!).map{|e|
						(!(past=~/#{e}/) && ev.el=~/#{e}/) || ev.el=~/#{e}./
					}.any?
					c_tie = [ev.el]-%w(= =:)==[]
					c_trem = past=~/%/ && ev.el=~/%/ && !(ev.el=~/%ATK/)
					c_rest = %w(r! s!).map{|e| past=~/#{e}/ && ev.el=="#{e}"}.any?
					c_xval = note_value(tp_a)[evt.du+tick]==nil
					c_mktie = (past=~/@/ || past=~/==/) && ev.el=~/==/

					if ev.el=~/(@|%ATK|rrr|sss)/ || n_rest || c_xval
						qa << evt
						evt = ev
					elsif c_tie || c_trem || c_rest || c_mktie
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
 
 
 	def recombine_tuplet(quad, tp)
		tick = Rational(tp[1]*tp[2], tp[0])
		bt = quad.map{|e| (e.dlook.sigma/tick).to_i}

		if tp[0]==tp[1]
			bt = [tp[0]].map{|e|
				if e%3==0
					[3]*(e/3)
				else
					[4]*(e/4)+[e%4]-[0]
				end
			}.flatten
		end

		tp_a = [bt, tp[1], tp[2]]

		while 0
			id = 0
			tm = 0
			cd = false
			bu = false

			while id<quad.size
				fo, la = quad[id], quad[id+1]

				if la!=nil
					fol, laf = fo.last, la.first
					nv = fol.du + laf.du
					if fo.size>1
						tm += fo[0..-2].dtotal
						bu = true
					end

					if @dotDuplet && tp.dot?
						nval = note_value_dot(tp)[nv]
					else
						nval = note_value(tp)[nv]
					end

					pos_table = {
						3 => {
							2 => [0, 1],
							3 => [0],
							6 => [0],
						},
						4 => {
							2 => [0, 1, 2],
							3 => [0, 1],
							4 => [0, 2],
							6 => [0, 2],
							8 => [0],
						},
					}

					npos = allowed_positions(tp_a, pos_table, nv)

					if tp[0]==tp[1] || tp[0]>=8		# (to be investigated)
						if @tidyTuplet!=nil && npos.all?{|e| tm!=e}
							nval = nil
						end
					end

					cond = [
						(fol.el=~/@/ || fol.el=='+' || [fol.el]-%w(= =:)==[]) && [laf.el]-%w(= =:)==[],
						fol.el=~/r!/ && laf.el=="r!",
						fol.el=~/s!/ && laf.el=="s!",
						fol.el=~/%/ && laf.el=~/%/ && !(laf.el=~/%ATK/),
						(fol.el=~/@/ || fol.el=~/==/) && laf.el=~/==/,
					]

omittedRest = [
	[
		fol.el=~/r!/ && laf.el=="r!",
		fol.el=~/s!/ && laf.el=="s!",
	].any?,
	@omitRest.include?(nv)
].all?

					if cond.any? && nval!=nil && !omittedRest
						fol.du += laf.du
						la.shift
						quad.delete_if{|e| e==[]}
						cd = cd||true
					end

					tm -= fo[0..-2].dtotal if bu
					tm += fo.dtotal
				end
				id += 1
			end
			break if cd == false
		end

		quad.flatten!
	end


	def assemble_bars(tuples, metre, final_bar)
		mtr_id = 0
		bars = []
		bar_residue = 0

		while tuples.size>0 || bar_residue>0
			mtr = metre.on(mtr_id)
			mtr = Rational(mtr[0].sigma*mtr[1]) if Array===mtr

			if tuples.dtotal<mtr
				filler = []
				tpl_add = []
				len = tuples.dtotal+filler.dtotal+bar_residue
				gap = mtr-len

				while gap>0
					tk = note_value(16).select{|e| e<=gap}.max[0]
					filler << [Event.new("r!", tk)]
					tpl_add << [1, 1, tk]
					gap -= tk
				end

				filler.reverse!
				tpl_add.reverse!
				tuples += filler
				@tpl_param += tpl_add
			end

			bar = []
			while bar.dtotal+bar_residue<mtr
				bar << tuples.shift
			end

			bar_residue = bar.dtotal+bar_residue-mtr
			bars << bar
			mtr_id += 1
		end

		bars = fit_into_final_bar(bars, metre, mtr_id, final_bar)
		bars
	end


	def fit_into_final_bar(bars, metre, mtr_id, final_bar)
		if final_bar!=nil
			if final_bar>bars.size
				(final_bar-bars.size).times{
					mtr = metre.on(mtr_id)
					ar = []
					tp = []
					if Fixnum === mtr
						mtr.times{
							ar << [Event.new("r!", 1r)]
							tp << [1, 1, 1]
						}
					else
						mtr[0].map{|e| mtr[1]*e}.each{|e|
							residue = e
							while residue>0
								du = note_value(2**16).select{|f| f<=residue}.max[0]
								ar << [Event.new("r!", du)]
								tp << [1, 1, Rational(1, du.denominator)]
								residue -= du
							end
						}
					end
					bars << ar
					@tpl_param += tp
					mtr_id += 1
				}
			else
				bars = bars[0..final_bar-1]
			end
		end
		bars
	end


	def connect_beat(bars, metre, tpl)

		# Associate tuplet and tuplet-number
		tx = 0
		barr = bars.map{|e|
			e.map{|f|
				t = tpl[tx]
				t = [1, 1, f[0].du] if f.size==1 && Math.log(f[0].du).abs%1==0
				z = [f, t]
				tx += 1
				z
			}
		}

		barr.each.with_index{|bar, idx|
			bv = bar.map{|e| e[0]}.dtotal
			mtr = metre.on(idx)

			if (Array===mtr && Rational(mtr[0].sigma*mtr[1])!=bv) || (Fixnum===mtr && mtr!=bv)
				msg = <<-EOS

LotusRoot >> Unexpected error
LotusRoot >> Total duration of bar (#{bv}) is different from the time signature (#{mtr})
LotusRoot >> #{mtr}
LotusRoot >> #{bar.look}
				EOS
				raise msg
			end

			while 0
				id = 0
				tm = 0
				cd = false

				while id<bar.size
					fo, la = bar[id], bar[id+1]

					if la!=nil
						fo_ev, fo_tp = fo
						la_ev, la_tp = la
						fol, laf = fo_ev.last, la_ev.first
						tm += fo_ev[0..-2].dtotal if fo_ev.size>1
						nv = fol.du + laf.du
						matchValue = note_value(fo_tp)[nv]!=nil

						if Array===mtr
							bt, ud = mtr
						else
							bt = [mtr]
							ud = 1
						end

						bt = bt.map{|e|
							if e%3==0
								[3]*(e/3)
							else
								[2]*(e/2)+[e%2]-[0]
							end
						}.flatten

						tp_a = [bt, bt.sigma, ud]

						pos_table = {
							2 => {
								1 => [0, 1/2r, 1],
								3/2r => [0, 1/2r],
#								2 => [0, 1],
								2 => [0],
								3 => [0, 1],
								4 => [0],
							},
							3 => {
								1 => [0, 1/2r, 1, 3/2r, 2],
								3/2r => [0, 1/2r, 1, 3/2r],
								2 => [0, 1, 2],
								3 => [0],
								6 => [0],
							},
						}

						npos = allowed_positions(tp_a, pos_table, nv)

						if npos.all?{|e| tm!=e}
							matchValue = false
						end

						Array===mtr ? mt=mtr[1] : mt=1
						if @dotDuplet && fo_tp.dot? && la_tp.dot?
							nval = [1,2,3,4,6,8].map{|e| Rational(e*3,8)*mt}
						else
							nval = [1,2,3,4,6,8].map{|e| Rational(e,2)*mt}
						end
						matchDup = [fol.du]-nval==[] && [laf.du]-nval==[]

						homoElem = [
							[laf.el]-%w(= =:)==[],
							[
								fo_ev.size==1 || la_ev.size==1,
								fol.el=~/%/,
								laf.el=~/%/,
								!(laf.el=~/%ATK/)
							].all?,
							fol.el=~/r!/ && laf.el=="r!",
							fol.el=~/s!/ && laf.el=="s!",
							fol.el=~/@/ && laf.el=~/==/,
							fol.el=~/==/ && laf.el=~/==/,
						].any?

						homoPlet = fo_tp[0]==fo_tp[1] && la_tp[0]==la_tp[1]

omittedRest = [
	[
		fol.el=~/r!/ && laf.el=="r!",
		fol.el=~/s!/ && laf.el=="s!",
	].any?,
	@omitRest.include?(nv)
].all?

						if matchValue && matchDup && homoElem && homoPlet && !omittedRest
							fol.du += laf.du
							la_ev.shift
							fo_tp = 16
							bar.delete_if{|e| e[0]==[]}
							cd = cd||true
						end

						tm += fo_ev[-1].du
					end
					id += 1
				end
				break if cd == false
			end
		}
		b = barr.map{|e| e.map{|f| f[0]}}
		t = barr.inject([]){|s,e| s += e.map{|f| f[1]}}
		[b, t]
	end


	def markup_tail(seq)
		past = nil
		u,v,w = nil, nil, nil 
		seq.each.with_index{|bar,x|
			bar.each.with_index{|tuple,y|
				tuple.each.with_index{|note,z|
					if past!=nil
						if note.el=~/==/
							seq[u][v][w].el.gsub!(/#Z.*?Z#/m, "")
						else
							seq[u][v][w].el.gsub!(/#Z(.*?)Z#/m, "\\1")
						end
					end
					u,v,w = x,y,z
					past = note
				}
			}
		}
		seq[u][v][w].el.gsub!(/#Z(.*?)Z#/m, "\\1")
	end


	def slur_over_tremolo(seq)
		past = nil
		u,v,w = nil, nil, nil 
		id = 0
		seq.each.with_index{|bar,x|
			bar.each.with_index{|tuple,y|
				tuple.each.with_index{|note,z|
					if past!=nil
						elms = [past.el, note.el].map{|e| e.scan(/%[A-Z]*/)[0]}
						ptr, ntr = elms

						if [
							elms==%w(%ATK %),
							elms==%w(% %ATK),
							elms==["%", nil],
						].any?
							seq[u][v][w].el = ptr + "SOT" + past.el.sub(ptr, "")
						end
						
						if ntr=="%" && id==seq.flatten.size-1
							seq[x][y][z].el = ntr + "SOT" + note.el.sub(ntr, "")
						end
					end
					u,v,w = x,y,z
					past = seq[x][y][z]
					id += 1
				}
			}
		}
	end

end