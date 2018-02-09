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
			mtr = Rational(mtr[0].sigma*mtr[1]) if Array===mtr

			if tuples.dtotal<mtr
				filler = []
				tpl_add = []
				len = tuples.dtotal+filler.dtotal+bar_residue
				gap = mtr-len

				while gap>0
					tk = note_value(16)
					tk = tk.select{|e| !(@omitRest.include?(e))}
					tk = tk.select{|e| e<=gap}.max[0]
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
#				t = [1, 1, f[0].du] if f.size==1 && Math.log(f[0].du).abs%1==0
				t = [1, 1, f[0].du.flatten.sigma] if f.size==1 && Math.log(f[0].du.flatten.sigma).abs%1==0
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

LotusRoot >> Total duration of bar (#{bv}) is different from the time signature (#{mtr})
LotusRoot >> #{mtr}
LotusRoot >> #{bar.look}
				EOS
				raise msg
			end

			while 0
				id = 0
				time = 0
				again = false

				while id<bar.size
					fo, la = bar[id], bar[id+1]

					if la!=nil
						fo_ev, fo_tp = fo
						la_ev, la_tp = la
						fol, laf = fo_ev.last, la_ev.first
						time += fo_ev[0..-2].dtotal if fo_ev.size>1
#						nv = fol.du + laf.du
						nv = fol.du.flatten.sigma + laf.du.flatten.sigma
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

#						omittedRest = bothRests && @omitRest.include?(nv)
						npos = allowed_positions(tp_a, pos_table, nv)

						if npos.all?{|e| time!=e} # || omittedRest
							matchValue = false
						end

						Array===mtr ? mt=mtr[1] : mt=1
						if @dotDuplet && fo_tp.dot? && la_tp.dot?
							nval = [1,2,3,4,6,8].map{|e| Rational(e*3,8)*mt}
						else
							nval = [1,2,3,4,6,8].map{|e| Rational(e,2)*mt}
						end
						matchDup = [fol.du.flatten.sigma]-nval==[] && [laf.du.flatten.sigma]-nval==[]

						sameElem = bothNotes || bothRests
						samePlet = fo_tp[0]==fo_tp[1] && la_tp[0]==la_tp[1]
p [fo_tp, la_tp, samePlet]
# p 0, fol.look
						if [matchValue, matchDup, sameElem, samePlet].all?
							fol.du += laf.du
							la_ev.shift
							fo_tp = 16
							bar.delete_if{|e| e[0]==[]}
							again = again || true
						end
# p 1, fol.look
#						time += fo_ev[-1].du
						time += fo_ev[-1].du.flatten.sigma
					end
					id += 1
				end
				break if again == false
			end
		}

		b = barr.map{|e| e.map{|f| f[0]}}
		t = barr.inject([]){|s,e|
p 9, e.look
			s += e.map{|f| f[1]}
		}
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


	def rest_dur(seq)
		omittedRest = ->(nte){
			[
				nte.el=~/(r!|s!|rrr|sss)/,
				Array===nte.du,
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

		seq.each.with_index{|bar,x|
			bar.each.with_index{|tuple,y|
				tuple.each.with_index{|note,z|
					if Array===note.du
						seq[x][y][z].du = note.du.flatten.sigma
					end
				}
			}
		}
		seq
	end
end