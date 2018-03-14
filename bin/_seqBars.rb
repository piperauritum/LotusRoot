require_relative '_override'
require_relative '_notation'

class DataProcess
	include Notation

	def assemble_bars(tuples, metre, final_bar)
		mtr_id = 0
		bars = []
		bar_residue = 0

		## fill with rests
		while tuples.size>0 || bar_residue>0
			mtr = metre.on(mtr_id)
			btotal = Rational(mtr.beat.sigma*mtr.unit)

			if tuples.map(&:evts).dtotal<btotal
				filler = []
				tpl_add = []
				len = tuples.map(&:evts).dtotal+filler.map(&:evts).dtotal+bar_residue
				gap = btotal-len

				while gap>0
					tick = note_value(16)
					tick = tick.select{|key, val| !(@avoidRest.include?(key))}
					tick = tick.select{|key, val| key<=gap}.max[0]
					tpp = [1, 1, tick].to_tpp
					evt = Event.new("r!", tick)
					filler << Tuplet.new(tpp, [evt])
					gap -= tick
				end

				filler.reverse!
				tpl_add.reverse!
				tuples += filler
				@tpl_param += tpl_add
			end

			bar = Bar.new(mtr)
#			bar = []
			while bar.tpls.map(&:evts).dtotal+bar_residue<btotal
#			while bar.map(&:evts).dtotal+bar_residue<btotal
				bar.tpls << tuples.shift
			end

			bar_residue = bar.tpls.map(&:evts).dtotal+bar_residue-btotal
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
					events = []
#					tpps = []
=begin
					if Fixnum === mtr
						mtr.times{
							tpp = [1, 1, 1].to_tpp
							evt = Event.new("r!", 1r)
							events << Tuplet.new(tpp, [evt])
						}
					else
=end
						mtr.beat.map{|e| mtr.unit*e}.each{|e|
#						mtr[0].map{|e| mtr[1]*e}.each{|e|
							residue = e
							while residue>0
								dur = note_value(2**16).select{|f| f<=residue}.max[0]
								tpp = [1, 1, Rational(1, dur.denominator)].to_tpp
								evt = Event.new("r!", dur)
								events << Tuplet.new(tpp, [evt])
								residue -= dur
							end
						}
#					end
					bar = Bar.new(mtr, events)

					bars << bar
#					bars << events
#					@tpl_param += tpps
					mtr_id += 1
				}
			else
				bars = bars[0..final_bar-1]
			end
		end
		bars
	end


	def connect_beat(bars)
		bars.each.with_index{|bar, bar_id|
			bar_dur = bar.tpls.map(&:evts).dtotal
			mtr = bar.mtr
#			bar_dur = bar.map(&:evts).dtotal
#			mtr = metre.on(bar_id)
			if Rational(mtr.beat.sigma*mtr.unit)!=bar_dur
#			if (Array===mtr && Rational(mtr[0].sigma*mtr[1])!=bar_dur) || (Fixnum===mtr && mtr!=bar_dur)
				puts <<-EOS

LotusRoot >> Total duration of bar (#{bar_dur}) is different from the time signature (#{mtr})
LotusRoot >> #{mtr}
				EOS
				pp bar
				raise
			end

			while 0
				bid = 0
				time = 0
				again = false

				while bid<bar.tpls.size
					fo, la = bar.tpls[bid], bar.tpls[bid+1]

					if la!=nil
						fo_ev, fo_tp = fo.evts, fo.par
						la_ev, la_tp = la.evts, la.par
						fol, laf = fo_ev.last, la_ev.first
						time += fo_ev[0..-2].dtotal if fo_ev.size>1
						beat_struc, unit_dur = mtr.ar

						bothNotes = [
							[laf.el]-%w(= =:)==[],
							[
								fo_ev.size==1 || la_ev.size==1,
								fol.el=~/%/,
								laf.el=~/%/,
								!(laf.el=~/%ATK/)
							].all?,
							fol.el=~/@/ && laf.el=~/==/,
							fol.el=~/==/ && laf.el=~/==/,
						].any?

						bothRests = [
							fol.el=~/r!/ && laf.el=="r!",
							fol.el=~/s!/ && laf.el=="s!",
						].any?

						if bothRests
							pos_table = {
								2 => {
									1 => [0, 1],
									2 => [0],
									4 => [0],
								},
								3 => {
									1 => [0, 1, 2],
									2 => [0],
									3 => [0],
								},
							}
						else
							pos_table = {
								2 => {
									1 => [0, 1/2r, 1],
									3/2r => [0, 1/2r],
									2 => [0, 1],
									3 => [0, 1],
									4 => [0],
								},
								3 => {
									1 => [0, 1/2r, 1, 3/2r, 2],
									3/2r => [0, 1/2r, 1, 3/2r],
									2 => [0, 1],
									3 => [0],
									6 => [0],
								},
							}
						end

						nv = fol.dsum + laf.dsum
						tp_ary = [beat_struc, beat_struc.sigma, unit_dur].to_tpp
						matchValue = note_value(tp_ary)[nv]!=nil

						npos = allowed_positions(tp_ary, pos_table, nv)
						matchValue = false if npos.all?{|e| time!=e}

						mt = mtr.unit
#						Array === mtr ? mt=mtr[1] : mt=1
						if @dotDuplet && fo_tp.dot? && la_tp.dot?
							nval = [1,2,3,4,6,8].map{|e| Rational(e*3,8)*mt}
						else
							nval = [1,2,3,4,6,8].map{|e| Rational(e,2)*mt}
						end
						matchDup = [fol.dsum]-nval==[] && [laf.dsum]-nval==[]

						sameElem = bothNotes || bothRests
						samePlet = fo_tp.even? && la_tp.even?

						if [matchValue, matchDup, sameElem, samePlet].all?
							fol.du = [fol.du, laf.du]
							la_ev.shift
							unit = fo.evts.dlook.flatten.min
							mul = (fo.evts.dtotal/unit).to_i
							bars[bar_id].tpls[bid].par = [mul, mul, unit].to_tpp

							if la.evts.size > 0
								unit = la.evts.dlook.flatten.min
								mul = (la.evts.dtotal/unit).to_i
								bars[bar_id].tpls[bid+1].par = [mul, mul, unit].to_tpp
							end

							bar.tpls.delete_if{|e| e.evts==[]}
							again = again || true
						end

						time += fo_ev[-1].dsum
					end
					bid += 1
				end
				break if again == false
			end
		}
		bars
	end


	def markup_tail(bars)
		past = nil
		u,v,w = nil, nil, nil 
		bars.each.with_index{|bar,x|
			bar.tpls.each.with_index{|tuple,y|
				tuple.evts.each.with_index{|note,z|
					if past!=nil
						if note.el=~/==/
							bars[u].tpls[v].evts[w].el.gsub!(/#Z.*?Z#/m, "")
						else
							bars[u].tpls[v].evts[w].el.gsub!(/#Z(.*?)Z#/m, "\\1")
						end
					end
					u,v,w = x,y,z
					past = note
				}
			}
		}
		bars[u].tpls[v].evts[w].el.gsub!(/#Z(.*?)Z#/m, "\\1")
		bars
	end


	def slur_over_tremolo(bars)
		past = nil
		u,v,w = nil, nil, nil 
		id = 0
		bars.each.with_index{|bar,x|
			bar.tpls.each.with_index{|tuple,y|
				tuple.evts.each.with_index{|note,z|
					if past!=nil
						elms = [past.el, note.el].map{|e| e.scan(/%[A-Z]*/)[0]}
						ptr, ntr = elms

						if [
							elms==%w(%ATK %),
							elms==%w(% %ATK),
							elms==["%", nil],
						].any?
							bars[u].tpls[v].evts[w].el = ptr + "SOT" + past.el.sub(ptr, "")
						end

						if ntr=="%" && id==bars.flatten.size-1
							bars[x].tpls[y].evts[z].el = ntr + "SOT" + note.el.sub(ntr, "")
						end
					end
					u,v,w = x,y,z
					past = bars[x].tpls[y].evts[z]
					id += 1
				}
			}
		}
		bars
	end


	def rest_dur(bars, metre)
		avoidedRest = ->(nte, mtr){
			[
				nte.el=~/(r!|s!|rrr|sss)/,
				Array === nte.du,
				[
					mtr!=nil && mtr.beat.uniq==[3] && nte.dsum==2,
					@avoidRest.include?(nte.dsum),
				].any?
			].all?
		}

		yet = true
		cnt = 0
		while yet
			bars.each.with_index{|bar,x|
				mtr = metre.on(x)
				bar.tpls.each.with_index{|tuple,y|
					tuple.evts.each.with_index{|note,z|
						if avoidedRest.call(note, mtr)
							bars[x].tpls[y].evts[z] = note.du.map.with_index{|d, i|
								rest = note.el.match(/(r!|s!|rrr|sss)/)[1]
								i==0 ? e=note.el : e=rest
								Event.new(e, d)
							}
							bars[x].tpls[y].evts.flatten!
						end
					}
				}
			}

			yet = false
			avd = []
			bars.each{|bar|
				bar.tpls.each{|tuple|
					tuple.evts.each{|note|
						if avoidedRest.call(note, nil)
							yet = true
							avd << note.dsum
						end
					}
				}
			}
			cnt += 1

			if cnt > 99
				puts "LotusRoot >> Could not avoid some rests. #{avd.uniq}"
				yet = false
			end
		end
		bars
	end


	def whole_bar_rest(bars)
		bars.map{|bar|
			wholebar = bar.tpls.map(&:evts).flatten
			wbel = wholebar.elook
			wbdu = wholebar.dlook

			if wbel[0]=~/r!/ && wbel[1..-1].map{|e| e=="r!"}.all?
				unit = wbdu.flatten.min
				mul = (wbdu.flatten.sigma/unit).to_i
				new_el = wbel[0].sub("r!", "R!")
				tpp = [mul, mul, unit].to_tpp
				evt = Event.new(new_el, wbdu)
				bar.tpls = [Tuplet.new(tpp, [evt])]
			end
			bar
		}
	end

end