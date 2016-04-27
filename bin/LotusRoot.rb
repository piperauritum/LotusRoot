require_relative '_process'
include Notation

class Score < DataProcess
	include Notation
	attr_reader :output
	attr_writer :pitchShift, :metre, :finalBar, :instName, :noInstName,
	:accMode, :autoAcc, :chordAcc, :altNoteName, :beam, :noTie, :pnoTrem,
	:fracTuplet, :tidyTuplet, :dotDuplet


	def initialize(_durations, _elements, _tuplets, _pitches)
		super(_tuplets)
		@tpl_data = unfold_elements(_durations, _elements)
		@pitch = _pitches-[nil]
		@instName = "hoge"
		@metre = [4]
		@accMode, @pitchShift = 0, 0
		@gspat, @gsrep = [], []
	end


	def sequence
		@pitch = pitch_shift(@pitch, @pitchShift)
		@tpl_data, @tpl_param = assemble_tuplets(@tpl_data, @tpl_param, @metre)
		@tpl_data = delete_suspensions(@tpl_data) if @noTie

		tuples = []
		idx = 0
		@tpl_data.inject("r!"){|past, tuple|
			tp = @tpl_param[idx]
			tick = Rational(tp[1]*tp[2], tuple.size)			
			
			reduc = ->(qt){
				rd = reduced_tuplets(tp)
				rd.select!{|e| e[0]==e[1]} if tp[0]==tp[1]				
				if rd!=[]
					rd.each{|tq|
						if qt.dlook.flatten.map{|d|							
							note_value(tq)[d]!=nil							
						}.all?
							tp = @tpl_param[idx] = tq						
						end
					}
				end
			}

			sd_tuplet, past = subdivide_tuplet(tuple.deepcopy, past, tick, tp)
			reduc.call(sd_tuplet)			
			rc_tuplet = recombine_tuplet(sd_tuplet.deepcopy, tp)					
			reduc.call(rc_tuplet)
			tuples << rc_tuplet
			
			idx += 1
		}

		ba = assemble_bars(tuples, @metre, @finalBar)
		@seq, @tpl_param = connect_beat(ba, @metre, @tpl_param)
		slur_over_tremolo(@seq)
	end


	def scribe
		self.sequence

		pch_id = -1
		tp, prev_tpl, tpp_id = nil, nil, 0
		prev_pch, prev_dur, prev_elm, prev_mtr = [], nil, nil, nil
		bracketing, beaming = nil, nil
		voice = ""

		##### MEASURE #####
		@seq.each.with_index{|bar, bar_id|
			mtr = @metre[bar_id % @metre.size]
			
			if Array === mtr
				beat_dur = mtr[1]
				bar_dur = mtr[0].sigma*beat_dur
			else
				beat_dur = 1
				bar_dur = mtr*beat_dur
			end
		
			##### TUPLET #####
			bar.each.with_index{|tuple, beat_id|
				tp = @tpl_param.on(tpp_id)
				
				dotted = [
					@dotDuplet!=nil,
					Array === tp,
					Math.log2(tp[0])%1==0,
					tp[1]%3==0,
					note_value_dot(tp)!=nil
				].all?

				##### NOTE #####
				tuple.each.with_index{|nte, nte_id|
					_el, _du = nte.ar

					# write note name
					abc = ->(pc){
						if Array === pc && pc.size>1
							acmd = @accMode
							acmd = auto_accmode(pc, @accMode) if @autoAcc
							eg = pc.map{|e|
								n = note_name(e, acmd, @altNoteName)
								n += "!" if prev_pch.include?(e) && !natural?(e) && @chordAcc
								n
							}.join(' ')
							prev_pch = pc
							eg = "<#{eg}>"
						else
							pc = pc[0] if Array === pc
							prev_pch = [pc]
							eg = note_name(pc, @accMode, @altNoteName)
						end
					}

					# tie
					voice += "~ " if [_el]-%w(= =:)==[]

					# when top of beat
					if nte_id==0

						# close beam
						if beaming
							voice += "]"
							beaming = false
						end

						# close bracket
						if bracketing
							voice += "} "
							bracketing = false
						end

						# line break
						voice += "\n" if beat_id==0
					end

					# tempo mark
					if /((TMP)(.*;))/ =~ _el
						x = $3.split(/;/)
						voice += "\\tempo #{x[0]} = #{x[1]} "
						_el = _el.sub(/TMP.*;/, "")
					end

					# time signature
					if beat_id==0 && mtr!=prev_mtr
						if Array === mtr
							nu = mtr[0].sigma
							de = (Rational(1, mtr[1])*4).to_i
							voice += "\\time #{nu}/#{de} "
						else
							voice += "\\time #{mtr}/4 "
						end
					end					
					prev_mtr = mtr

					# grace note
					if /((GRC)(.*;))/ =~ _el
						gval, gnum = $3.split(/;/).map(&:to_i)
						gtxt = ""
						gnum.times{|i|
							pch_id += 1
							gtxt += abc.call(@pitch.on(pch_id))
							gtxt += "#{gval}" if i==0
							gtxt += " " if i<gnum-1
						}
						voice += "\\acciaccatura {#{gtxt}} "
						_el = _el.sub(/GRC.*;/, "")
						prev_dur = gval
					end

					### main note ###
					ntxt = ""

					# before note
					%w(@ r! s! rrr sss %+).each{|e|
						ntxt += _el.sub(/#{e}.*/m, "") if _el=~/#{e.sub("+", "")}/
					}

					# tuplet bracket
					if nte_id==0 && !bracketing
						if !dotted && ((Fixnum===tp && Math.log2(tp)%1>0) || (Array===tp && tp[0]!=tp[1]))
							bracketing = true
							tp_a = @tpl_param.on(tpp_id)
							if Array === tp_a
								ntxt += "\\fractpl " if @fracTuplet!=nil # config.ly
								ntxt += "\\tuplet #{tp_a[0]}/#{tp_a[1]} {"
							else
								den = 2**Math.log2(tp_a).to_i
								ntxt += "\\tuplet #{tp_a}/#{den} {"
							end
						end
					end

					# put note
					case _el
					when /r!|rrr/
						ntxt+="r"		# (whole bar rest should not be used)
					when /s!|sss/
						ntxt += "s"
					else
						pch_id += 1 if _el=~/@|%%/	# next pitch
						if _el=~/%/		# two-notes tremolo
							/((%+)(C?)(\d+))/ =~ _el
							tr_dur = $4.to_i
							t = [*0..4].map{|e| 2**e*tp[0]}.select{|e| e<=16}.max
							tr_times = note_value(t).key((tr_dur/2).to_s)
							tr_times = (_du/tr_times).to_i
							ntxt += "\\repeat tremolo #{tr_times} {"
							ntxt += "\\change Staff = lower " if @pnoTrem
						else
							ntxt += abc.call(@pitch.on(pch_id))
						end
					end

					# note value
					if dotted
						nv = note_value_dot(tp)[_du]
					else
						nv = note_value(tp)[_du]
					end
					
					if nv==nil
						if dotted
							vv = note_value_dot(tp)
						else
							vv = note_value(tp)
						end
						msg = <<-EOS

LotusRoot >> There is not notation of the duration (#{_du}) for tuplet (#{tp}).
LotusRoot >> #{tuple.look}
LotusRoot >> #{vv}
						EOS
						raise msg
					end
					
					if !(_el=~/%/) && (
						(prev_dur!=_du || prev_tpl!=tp || prev_elm=~/%/) || 
						(_du==bar_dur && (_el=~/r!|s!/))
						)
						ntxt += nv
					end

					# tremolo
					ntxt += ":" if _el=="=:"

					# after note
					%w(@ r! s! rrr sss).each{|e|
						ntxt += _el.sub(/.*#{e}/m, "") if _el=~/#{e}/
					}

					# two-notes tremolo
					if _el=~/%/
						ta = @pitch.on(pch_id)
						tr_txt = _el.sub(/.*%+C?\d+/, "")
						tr_dat = _el.scan(/\[.+\]/)[0]
						tr_note = tr_dat.gsub(/\[|\]|\s/, "").split(",").map{|e| e.to_f+@pitchShift}

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

					##### beam #####
					if @beam!=nil
						if nte_id==0
							n = nte_id
							bm = true
							elz = []

							while 0
								n_el, n_va = tuple[n].ar
								elz << n_el

								nv = note_value(@tpl_param.on(tpp_id))[n_va]
								%w(4 2 1).each{|e|
									bm = false if nv!=nil && nv.gsub(".","")==e
								}
								n += 1

								# search forward
								break if n==tuple.size
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
							bm = false if beaming==true

							if bm
								voice += "["
								beaming = true
							end
						end
					end

					prev_dur = _du
					prev_tpl = tp
					prev_elm = _el
					voice += " "
				}
				tpp_id += 1
			}
		}

		# close voice
		voice += "]" if beaming
		voice += "}" if bracketing
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

