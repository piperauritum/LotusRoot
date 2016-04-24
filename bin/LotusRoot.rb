require_relative '_dataprocess'
include Notation

class Score < DataProcess
	include Notation
	attr_reader :output
	attr_writer :instName, :measure, :accMode, :pchShift,
	:noInstName, :autoAcc, :chordAcc, :beam, :pnoTrem,
	:noTie, :fracTuplet, :dotDuplet, :finalBar, :subdiv, :fmRest


	def initialize(_dur, _elm, _tpl, _pch)
		super(_tpl)
		@seq = unfold_elements(_dur, _elm)
		@pch = _pch-[nil]
		@instName = "hoge"
		@measure = [4]
		@accMode, @pchShift = 0, 0
		@gspat, @gsrep = [], []
	end


	def sequence
		@pch = pitch_shift(@pch, @pchShift)
		@seq, @tpl = assemble_tuplets(@seq, @tpl, @measure)
		@seq = delete_suspensions(@seq) if @noTie

		tuples = []
		idx = 0
		@seq.inject("r!"){|past, tuple|
			tp = @tpl.on(idx)
			tick = Rational(tp[1]*tp[2], tuple.size)
			s_tuplet, past = subdivide_tuplet(tuple.deepcopy, past, tick, tp)
			c_tuplet = recombine_tuplet(s_tuplet.deepcopy, tp)
#			tuples << s_tuplet.flatten
			tuples << c_tuplet
			idx += 1
		}

		bars = assemble_bars(tuples, @measure, @finalBar)
		@note, @tpl = connect_beat(bars, @measure, @tpl)
#		@note = bars
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
		tpl_id = 0

		@note.each.with_index{|bar, bar_id|
			tm = @measure[bar_id % @measure.size]
			if Array === tm
				beat_dur = tm[1]
				bar_dur = tm[0].sigma*beat_dur
			else
				beat_dur = 1
				bar_dur = tm*beat_dur
			end
			bar.each.with_index{|tuple, bt_id|

				# tuplet number
				tp = @tpl.on(tpl_id)
				dotted = [
					@dotDuplet!=nil,
					Array===tp,
					Math.log2(tp[0])%1==0,
					tp[1]%3==0,
					note_value_dot(tp)!=nil
				].all?

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
						voice += "\n" if bt_id==0
					end

					# tempo mark
					if /((TMP)(.*;))/ =~ _el
						x = $3.split(/;/)
						voice += "\\tempo #{x[0]} = #{x[1]} "
						_el = _el.sub(/TMP.*;/, "")
					end

					# time signature
					if bt_id==0 && tm!=pre_tm
						if Array === tm
							nu = tm[0].sigma
							de = (Rational(1, tm[1])*4).to_i
							voice += "\\time #{nu}/#{de} "
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
					if nte_id==0 && !brac
						if !dotted && ((Fixnum===tp && Math.log2(tp)%1>0) || (Array===tp && tp[0]!=tp[1])) # &&
					#	(tuple.size>1 || (tuple.size==1 && note_value(16)[_du]==nil))
							brac = true
							if @subdiv!=nil && basemom!=1
								ntxt += "\\bsmY "	# config.ly
								basemom = 1
							end

							tp_a = @tpl.on(tpl_id)
							if Array===tp_a
								ntxt += "\\fractpl " if @fracTuplet!=nil # config.ly
								ntxt += "\\tuplet #{tp_a[0]}/#{tp_a[1]} {"
							else
								den = 2**Math.log2(tp_a).to_i
								ntxt += "\\tuplet #{tp_a}/#{den} {"
							end
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
						if _du==bar_dur && @fmRest!=nil
						### not work when sco.measure = [[[2,2,1],1/2r]] ###
							ntxt+="R"
						else
							ntxt+="r"
						end
					when /s!|sss/
						ntxt += "s"
					else
						pc_id += 1 if _el=~/@|%%/	# next pitch
						if _el=~/%/		# two-notes tremolo
							/((%+)(C?)(\d+))/ =~ _el
							tr_dur = $4.to_i
							t = [*0..4].map{|e| 2**e*tp[0]}.select{|e| e<=16}.max
							tr_times = note_value(t).key((tr_dur/2).to_s)
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
					if dotted
						nv = note_value_dot(tp)[_du]
					else
						nv = note_value(tp)[_du]
					end
					nv = note_value(16)[_du] if nv==nil
					
					if nv==nil
						dotted ? vv = note_value_dot(tp) : vv = note_value(tp)
						msg = <<-EOS

LotusRoot >> There is not notation of the duration (#{_du}) for tuplet (#{tp}).
LotusRoot >> #{tuple.look}
LotusRoot >> #{vv}
						EOS
						raise msg
					end
					
					ntxt += nv if !(_el=~/%/) &&
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

								nv = note_value(@tpl.on(tpl_id))[n_va]
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
				tpl_id += 1
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

