require_relative '_override'
require_relative '_notation'

class DataProcess
	include Notation

	def assemble_bars(tuples, metre, final_bar)
		mtr_id = 0
		bars = []
		bar_residue = 0

		while tuples.size>0 || bar_residue>0
			mtr = metre.on(mtr_id)
			mtr = Rational(mtr[0].sigma*mtr[1]) if Array === mtr

			if tuples.dtotal<mtr
				filler = []
				len = tuples.dtotal+filler.dtotal+bar_residue
				gap = mtr-len

				while gap>0
					tick = note_value(16)
					tick = tick.select{|key, val| !(@omitRest.include?(key))}
					tick = tick.select{|key, val| Math.log2(key.numerator)%1==0}
					tick = tick.select{|key, val| key<=gap}.max[0]
					filler << tick
					gap -= tick
				end

				filler = filler.reverse.inject([]){|s,e|
					s.size==0 ? s=[e] : s=[s,e]
				}
				tpl = filler.flatten
				len = (tpl.sigma/tpl.min).to_i
				tpl_add = [len, len, tpl.min].to_tpp
				filler = [Event.new("r!", filler)]
				tuples << filler
				@tpl_param << tpl_add
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
					evts = []
					tpps = []

					if Fixnum === mtr
						mtr.times{
							evts << [Event.new("r!", 1r)]
							tpps << [1, 1, 1].to_tpp
						}
					else
						mtr[0].map{|e| mtr[1]*e}.each{|e|
							residue = e
							while residue>0
								dur = note_value(2**16).select{|f| f<=residue}.max[0]
								evts << [Event.new("r!", dur)]
								tpps << [1, 1, Rational(1, dur.denominator)].to_tpp
								residue -= dur
							end
						}
					end

					bars << evts
					@tpl_param += tpps
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
		tid = 0
		beat_n_tpp = bars.map{|bar|
			bar.map{|beat|
				tpp = tpl[tid]

## the following is needed ?? (2018.2.11)
# tpp = [1, 1, beat[0].du].to_tpp if beat.size==1 && Math.log2(beat[0].du).abs%1==0
raise "\n### the previous line is needed ###\n" if tpl[tid].ar!=tpp.ar

				tid += 1
				[beat, tpp]
			}
		}

		beat_n_tpp.each.with_index{|bar, bar_id|
			bar_dur = bar.map{|e| e[0]}.dtotal
			mtr = metre.on(bar_id)

			if (Array===mtr && Rational(mtr[0].sigma*mtr[1])!=bar_dur) || (Fixnum===mtr && mtr!=bar_dur)
				msg = <<-EOS

LotusRoot >> Total duration of bar (#{bar_dur}) is different from the time signature (#{mtr})
LotusRoot >> #{mtr}
LotusRoot >> #{bar.look}
				EOS
				raise msg
			end

			while 0
				bid = 0
				time = 0
				again = false

				while bid<bar.size
					fo, la = bar[bid], bar[bid+1]

					if la!=nil
						fo_ev, fo_tp = fo
						la_ev, la_tp = la
						fol, laf = fo_ev.last, la_ev.first
						time += fo_ev[0..-2].dtotal if fo_ev.size>1
						nv = fol.dsum + laf.dsum
						matchValue = note_value(fo_tp)[nv]!=nil

						if Array === mtr
							beat_struc, unit_dur = mtr
						else
							beat_struc = [mtr]
							unit_dur = 1
						end

						beat_struc = beat_struc.map{|e|
							if e%3==0
								[3]*(e/3)
							else
								[2]*(e/2)+[e%2]-[0]
							end
						}.flatten

						tp_ary = [beat_struc, beat_struc.sigma, unit_dur]

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
									3/2r => [0, 1/2r],
									2 => [0],
									3 => [0, 1],
									4 => [0],
								},
								3 => {
									1 => [0, 1, 2],
									3/2r => [0, 1/2r, 1, 3/2r],
									2 => [0, 1],
									3 => [0],
									6 => [0],
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
									2 => [0, 1, 2],
									3 => [0],
									6 => [0],
								},
							}
						end

						npos = allowed_positions(tp_ary, pos_table, nv)
						matchValue = false if npos.all?{|e| time!=e}

						Array === mtr ? mt=mtr[1] : mt=1
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
							beat_n_tpp[bar_id][bid][1] = tuplet_num_to_param(16)
							bar.delete_if{|e| e[0]==[]}
							again = again || true
						end

						time += fo_ev[-1].dsum
					end
					bid += 1
				end
				break if again == false
			end
		}

		seq = beat_n_tpp.map{|e| e.map{|f| f[0]}}
		tpp = beat_n_tpp.inject([]){|s,e| s += e.map{|f| f[1]}}
		[seq, tpp]
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
		seq
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
		seq
	end


	def rest_dur(seq, tpp)
		omittedRest = ->(nte){
			[
				nte.el=~/(r!|s!|rrr|sss)/,
				Array === nte.du,
				@omitRest.include?(nte.du.flatten.sigma)
			].all?
		}

		yet = true
		while yet
			seq = seq.map{|bar|
				bar.map{|tuple|
					tuple.map{|note|
						if omittedRest.call(note)
							note.du.map{|h| Event.new(note.el, h)}
						else
							note
						end
					}.flatten
				}
			}

			yet = false
			seq.flatten.each{|note|
				yet = true if omittedRest.call(note)
			}
		end
		seq
	end

end