require_relative 'meta'

module Notation
	PPQN = 16	# Pulses per quarter note
	
	def note_value
		vd = [*0..6].map{|e|	# duple notes
			x = 2**e
			[x, "#{PPQN*4/x}"]
		}

		vt = [*1..5].map{|e|	# dotted notes
			x = PPQN*4/(2**e)
			x = x.to_s + "."
			[2**e*3/2, "#{x}"]
		}

		val = (vd+vt).sort{|x,y| x[0]<=>y[0]}

		ha = [*1..16].map{|tpl|
			mn = Math.log2(tpl).to_i
			mn = PPQN/2**mn	
			va = val.select{|v|	
				v[0]>=mn && (v[0]<=mn*tpl || Math.log2(tpl)%1==0)
			}
			va = va.map{|v|
				[Rational(v[0],mn) * Rational(PPQN, tpl), v[1]]
			}
			va += val.select{|v| v[0]==PPQN}.map{|v| [Rational(v[0]), v[1]]}
			Hash[*va.uniq.flatten]
		}
		ha.insert(0, nil)
	end

	
	def note_name(pc, acc=0)	
		nname = [
			%w(c cis d dis e f fis g gis a ais b),
			%w(c des d ees e f ges g aes a bes b),
		]
		
		# quarter tone
		qname = %w(cih deh dih eeh feh fih geh gih aeh aih beh ceh)
#		qname = %w(cih cisih dih disih eih fih fisih gih gisih aih aisih bih)	# alt
		
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
		
		# alternate 1/8-tone accidentals (arrow)
	#	if na.length==2
	#		na = "\\eup #{na}" if pc%1==0.25
	#		na = "\\edn #{na}" if pc%1==0.75
	#	end
		
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


	def echo(ev)
		case ev
		when Array
			ev.map{|e| Array === e ? echo(e) : e.ar}
		when nil
			nil
		else
			ev.ar
		end
	end
	
	
	def vtotal(ev)
		echo(ev).flatten.inject(0){|s,e| Rational === e ? s+e : s}
	end

end


class Event
	attr_accessor :el, :va
	
	def initialize(e, v)
		@el, @va = e, v		
	end
	
	def ar
		[@el, @va]
	end
end


class Score
	include Notation
	attr_reader :output
	attr_writer :instName, :noInstName, :measure, :pchShift, 
	:accMode, :autoAcc, :chordAcc, :beam, :noTie, :redTupRule, :pnoTrem, :finalBar, :subdiv


	def initialize(_dur, _elm, _tpl, _pch)
		@seq = unfold_element(_dur, _elm)		
		@tpl = _tpl
		@pch = _pch-[nil]
		@instName = "hoge"
		@measure = [4]
		@accMode, @pchShift = 0, 0
		@noInstName, @autoAcc, @chordAcc, @beam, @pnoTrem, @redTupRule, @finalBar, @subdiv = [nil]*8
		@gspat, @gsrep = [], []
	end


	def sequence
		@pch = pitch_shift(@pch, @pchShift)
		@tpl = reduce_tuplet(@measure, @seq, @tpl, &@redTupRule)
		@seq = make_tuplet(@seq, @tpl)
		@seq = delete_syncop(@seq) if @noTie

		ary = []
		@seq.inject("r!"){|past, tuple|
			tick = Rational(PPQN, tuple.size)
			quad, past = quad_event(tuple, past, tick)
			ary << connect_quad(quad, tuple.size)
		}
		@note = connect_beat(ary, @measure)		
		slur_over_tremolo(@note)
	end

	
	def scribe		
		self.sequence

		pc_id = -1
		pre_pc, pre_du, pre_el, pre_tm = [], nil, nil, nil
		tp, pre_tp, tp_id = nil, nil, -1
		brac, beamed = nil, nil		
		voice = ""
		basemom = nil

		@note.each.with_index{|bar, bar_id|
			tm = @measure[bar_id % @measure.size]
			if Array === tm
				beat_dur = Rational(PPQN, tm[1])
				bar_dur = tm[0].sigma*beat_dur
			else
				beat_dur = PPQN
				bar_dur = tm*beat_dur
			end

			bar.each.with_index{|tuple, tpl_id|				

				# tuplet number
				tp = tuple.map(&:va).map{|e| e/PPQN}.map(&:denominator).max

				tuple.each.with_index{|nte, nte_id|
					_el, _du = nte.ar
			
					# write note name
					abc = ->(pc){
						if Array === pc && pc.size>1
							acmd = @accMode
							acmd = auto_accmode(pc, @accMode) if @autoAcc							
							eg = pc.map{|e|
								n = note_name(e, acmd)
								n += "!" if pre_pc.include?(e) && !natural?(e) && @chordAcc
								n
							}.join(' ')
							pre_pc = pc							
							eg = "<#{eg}>"							
						else
							pc = pc[0] if Array === pc
							pre_pc = [pc]
							eg = note_name(pc, @accMode)							
						end
					}

					# tie
					voice += "~ " if [_el]-%w(= =:)==[]

					# when top of beat				
					if nte_id==0					

						# close beam
						if beamed
							voice += "]"
							beamed = false
						end

						# close bracket
						if brac
							voice += "} "
							brac = false
						end
						
						# line break
						voice += "\n" if tpl_id==0
					end
					
					# tempo mark
					if /((TMP)(.*;))/ =~ _el
						x = $3.split(/;/)
						voice += "\\tempo #{x[0]} = #{x[1]} "
						_el = _el.sub(/TMP.*;/, "")
					end
					
					# time signature
					if tpl_id==0 && tm!=pre_tm
						if Array === tm
							voice += "\\time #{tm[0].sigma}/#{4*tm[1]} "
						else
							voice += "\\time #{tm}/4 "
						end
					end
					pre_tm = tm
					
					# grace note
					if /((GRC)(.*;))/ =~ _el
						gval, gnum = $3.split(/;/).map(&:to_i)
						gtxt = ""
						gnum.times{|i|
							pc_id += 1							
							gtxt += abc.call(@pch.on(pc_id))
							gtxt += "#{gval}" if i==0
							gtxt += " " if i<gnum-1
						}
						voice += "\\acciaccatura {#{gtxt}} "
						_el = _el.sub(/GRC.*;/, "")
						pre_du = gval
					end

					### main note
					ntxt = ""
					
					# before note					
					%w(@ r! s! rrr sss %+).each{|e|
						ntxt += _el.sub(/#{e}.*/m, "") if _el=~/#{e.sub("+", "")}/
					}

					# tuplet bracket
					if nte_id==0
						if Math.log2(tp)%1>0 && !brac
							brac = true
							mul = vtotal(tuple)/PPQN
							nme = (tp*mul).to_i
							den = (2**(Math.log2(tp).to_i)*mul).to_i
							if @subdiv!=nil && basemom!=1
								ntxt += "\\bsmY "
								basemom = 1
							end
							ntxt += "\\tuplet #{nme}/#{den} {"
						else
							if @subdiv!=nil && basemom!=0
								ntxt += "\\bsmX "
								basemom = 0
							end
						end
					end

					# put note
					case _el
					when /r!|rrr/
						_du==bar_dur ? ntxt+="R" : ntxt+="r"						
					when /s!|sss/
						ntxt += "s"
					else
						pc_id += 1 if _el=~/@|%%/	# next pitch
						if _el=~/%/		# two-notes tremolo
							/((%+)(C?)(\d+))/ =~ _el
							tr_dur = $4.to_i							
							t = [*0..4].map{|e| 2**e*tp}.select{|e| e<=16}.max
							tr_times = note_value[t].key((tr_dur/2).to_s)
							tr_times = (_du/tr_times).to_i
							ntxt += "\\repeat tremolo #{tr_times} {"
							ntxt += "\\change Staff = lower " if @pnoTrem
						else
							ntxt += abc.call(@pch.on(pc_id))
						end						
					end
					
					# delete arrow
				#	%w(\\eup \\edn).each{|e| ntxt.sub!(e, "")} if _el=~/=/

					# note value
					ntxt += note_value[tp][_du] if !(_el=~/%/) &&
					((pre_du!=_du || pre_tp!=tp || pre_el=~/%/) || (_du==bar_dur && (_el=~/r!|s!/)))
					
					# tremolo
					ntxt += ":" if _el=="=:"

					# after note
					%w(@ r! s! rrr sss).each{|e|
						ntxt += _el.sub(/.*#{e}/m, "") if _el=~/#{e}/
					}

					# two-notes tremolo
					if _el=~/%/
						ta = @pch.on(pc_id)
						tr_txt = _el.sub(/.*%+C?\d+/, "")
						tr_dat = _el.scan(/\[.+\]/)[0]
						tr_note = tr_dat.gsub(/\[|\]|\s/, "").split(",").map{|e| e.to_f+@pchShift}
						
						if !(Array===ta) && tr_note.size==1
							tr_abc = abc.call([ta, tr_note[0]])
							tr_abc = tr_abc.gsub(/<|>/, "").split(" ")
						else
							tr_abc = [abc.call(ta), abc.call(tr_note)]
						end
						tr_txt = tr_txt.sub(tr_dat, "")
						
						case _el
						when /%%C/
							tr_txt = "#{tr_txt} (#{tr_abc[1]}}"
						when /%C/
							tr_txt = "#{tr_txt} #{tr_abc[1]})}"
						when /%%/
							tr_txt = "#{tr_txt} (#{tr_abc[1]})}"
						else
							tr_txt = "#{tr_txt} #{tr_abc[1]}}"
						end
						
						ntxt += tr_abc[0]
						ntxt += tr_dur.to_s						
						ntxt += " \\change Staff = upper" if @pnoTrem
						ntxt += tr_txt
					end

					voice += ntxt

					### beam
					if @beam!=nil
						if nte_id==0
							n = nte_id
							bm, go = true, true
							elz = []
							
							while go
								n_el, n_va = tuple[n].ar
								elz << n_el
	
								nv = note_value[tp][n_va]
								%w(4 2 1).each{|e|
									bm = false if nv!=nil && nv.gsub(".","")==e
								}
								n += 1

								# search forward
								go = false if n==tuple.size # || va_sum%beat_dur==0
							end

							# only the first note
							eq = elz.map{|e| e=~/@/ ? 1 : 0 }
							bm = false if eq[0]==1 && (eq-[0]).size==1
							
							# no rest
							eq = elz.map{|e| e=~/r!|s!|rrr|sss/ ? 1 : 0 }.sigma
							bm = false if eq==0
							
							# include two-notes tremolo or grace notes
							eq = elz.map{|e| e=~/%|GRC/ ? 1 : 0 }.sigma
							bm = false if eq>0
							
							# only rest or tie
							eq = elz.map{|e| e=~/r!|s!|rrr|sss|\A=\Z|\A=:\Z/ ? 0 : 1 }.sigma
							bm = false if eq==0
							
							# already beamed
							bm = false if beamed==true

							if bm
								voice += "["
								beamed = true
							end
						end
					end

					pre_du = _du
					pre_tp = tp
					pre_el = _el
					voice += " "
				}
			}
		}

		# close voice
		voice += "]" if beamed
		voice += "}" if brac
		if @noInstName==nil
			voice = "#{@instName} = {#{voice}\n}"
		end
		voice
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
	
	
	# Reduce tuplet on short beat.
	def reduce_tuplet(measure, seq, tpls, &block)
		i, j = 0, 0
		tp = []
		se = seq.dup
		me = measure.map{|e|
			Array === e ? e[0].map{|f| f.to_f/e[1]} : [1]*e
		}.flatten

		block = lambda{|num_tuplet, ratio| [num_tuplet*ratio, 1].max} if block==nil
		
		while se.size>0
			u = tpls.on(j)
			u = block.call(u, me.on(i)) if me.on(i)<1
			se.slice!(0, u)
			tp << u
			i += 1
			j += 1
		end

		raise "wrong tuplet (less than 1) => #{tp}" if tp.min<1
		tp
	end

	
	def make_tuplet(ary, tpl=0)
		# ary = ["@", "=", "=", "="]; tpl = [6]
		# => [["@", "=", "=", "=", "r!", "r!"]]

		if Array === tpl
			arx = []
			idx = 0
			while ary.size>0
				tp = tpl.on(idx)
				if ary.size>tp
					arx << ary.slice!(0, tp)
				else
					ay = ary.slice!(0, ary.size)
					ay += Array.new(tp-ay.size, "r!")
					arx << ay
				end
				idx += 1
			end
			ary = arx.dup
			
		elsif tpl>0
			(tpl-ary.size%tpl).times{ ary << "r!" } if ary.size%tpl>0
			ary = ary.each_slice(tpl).to_a
		end
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
	
		qv = vtotal(quad)		
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
					nval = note_value[dv][fol.va + laf.va]

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
		
		raise "invalid value data" if qv!=vtotal(quad)
		quad.flatten!
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
						ary_beat << [Event.new("r!", Rational(PPQN))]		# rest filling
					}
				end
				bars << ary_beat.slice!(0, meas)
				
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

		# fit into final-bar
		if @finalBar!=nil
			if @finalBar>bars.size
				(@finalBar-bars.size).times{
					meas = measure.on(idx)
					ar = []
					if Fixnum === meas
						meas.times{
							ar << [Event.new("r!", Rational(PPQN))]
						}
					else
						ar = []
						meas[0].each{|e|
							ar << [Event.new("r!", Rational(PPQN*e, meas[1]))]
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

		bars = mold_bar(ary_beat, measure)
		bars.each{|bar|
			bv = vtotal(bar)

			while 0
				id = 0
				cd = false
				
				while id<bar.size
					fo, la = bar[id], bar[id+1]
					
					if la!=nil
						fol, laf = fo.last, la.first
			
						nv = fol.va + laf.va
						matchValue = note_value[16][nv]!=nil
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

			raise "invalid value data" if bv!=vtotal(bar)
		}
	end
	
	
	def slur_over_tremolo(seq)
		past = nil
		u,v,w = nil, nil, nil 
		id = 0
		seq.each.with_index{|bar,x|
			bar.each.with_index{|tuple,y|
				tuple.each.with_index{|note,z|
					if past!=nil
						ntr = note.el.scan(/%+/)[0]
						ptr = past.el.scan(/%+/)[0]
						if (ptr=="%%" && ntr=="%") || (ptr=="%" && ntr==nil)
							seq[u][v][w].el = ptr + "C" + past.el.sub(ptr, "")
						elsif ntr=="%" && id==seq.flatten.size-1
							seq[x][y][z].el = ntr + "C" + note.el.sub(ntr, "")
						end
					end
					u,v,w = x,y,z
					past = seq[x][y][z]
					id += 1			
				}
			}
		}
	end

	
	def add_replace(pattern, replacement)
		@gspat << pattern
		@gsrep << replacement
	end	


	def do_gsub(txt)
		if @gspat!=[]
			@gspat.zip(@gsrep).each{|x,y|
				txt = txt.gsub(x, y)
			}
		end
		txt
	end


	def gen
		s = self.scribe
		@output = do_gsub(s)
	end


	def print
		puts @output
	end


	def export(fname)
	#	Dir::chdir(File.dirname(__FILE__))
		f = File.open(fname, 'w')
		n = File.absolute_path(fname)
		puts "exported > #{n}"	
		f.puts @output
		f.close		
	end
end

