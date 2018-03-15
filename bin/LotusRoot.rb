require_relative '_seqTuplets'
require_relative '_seqBars'
require_relative '_scribe'
include Notation

class Score < DataProcess
	include Notation
	attr_reader :output
	attr_writer :pitchShift, :metre, :finalBar, :namedMusic, :noMusBracket,
	:accMode, :autoChordAcc, :reptChordAcc, :altNoteName, :beamOverRest, :noTieAcrossBeat, # :pnoTrem,
	:fracTuplet, :tidyTuplet, :dotDuplet, :avoidRest, :wholeBarRest, :splitBeat


	def initialize(_durations, _elements, _tuplets, _pitches)
		super(_tuplets)
		@elems = unfold_elements(_durations, _elements)
		@pitch = _pitches-[nil]
		@namedMusic = "hoge"
		@metre = [4]
		@accMode, @pitchShift = 0, 0
		@gspat, @gsrep = [], []
		@avoidRest = []
	end


	def sequence
		@pitch = pitch_shift(@pitch, @pitchShift)
		@metre = process_metre(@metre)
		tplts = assemble_tuplets(@elems, @tpl_param, @metre)
		tplts = delete_ties_across_beats(tplts) if @noTieAcrossBeat # ??

		new_tplts = []
		idx = 0
		tplts.inject(Tuplet.new){|prev_tplt, tplt|
			tpar = tplt.par
			tick = Rational(tpar.denom*tpar.unit, tplt.evts.size)

			reduc = ->(tup){
				abbr = tpar_abbreviations(tpar)
				abbr.select!{|e| e.even?} if tpar.even?
				if abbr!=[]
					abbr.each{|ab|
						tk = ab.tick
						dur_map = tup.evts.flatten.map{|e| e.dsum}

						if dur_map.map{|du|
							(du/tk)%1==0 && note_value(ab)[du]!=nil
						}.all?
							len = dur_map.map{|e| (e/tk).to_i}
							len = len.map{|e| [*1..e].inject([]){|s,f| s.size==0 ? s=[tk] : s=[s,tk] }}

							lid = 0
							def redu(ary, len, lid)
								if Array===ary
									ary.each.with_index{|a,i|
										redu(a, len, lid)
										lid += 1
									}
								else
									ary.du = len[lid]
								end
							end
							redu(tup.evts, len, lid)

							tpar = tup.par = ab
							tick = tpar.tick
						end
					}
				end
			}

			## _seqTuplets.rb ##
			prev_tpar = tpar
			tpar_check = subdivide_tuplet(tplt, prev_tplt, tick, false)[0]
			reduc.call(tpar_check)

			if prev_tpar.ar == tpar.ar
				subdivided, prev_tplt = subdivide_tuplet(tplt, prev_tplt, tick)
			else
				subdivided, prev_tplt = subdivide_tuplet(tpar_check, prev_tplt, tick)
			end
			reduc.call(subdivided)

			recombined = recombine_tuplet(subdivided)
			reduc.call(recombined)
			new_tplts << recombined
			idx += 1
		}

		## _seqBars.rb ##
		bars = assemble_bars(new_tplts, @metre, @finalBar)
		bars = connect_beat(bars) if @splitBeat==nil
		bars = markup_tail(bars)
		bars = slur_over_tremolo(bars)
		bars = rest_dur(bars, @metre)
		bars = whole_bar_rest(bars) if @wholeBarRest!=nil
		@seq = bars
	end


	def scribe
		@pch_id  = -1
		@prev_pch = []
		@prev_dur, @prev_elm, @prev_tpl, @prev_mtr = [nil]*4
		@bracketing, @beaming = nil, nil
		@voice = ""

		##### MEASURE #####
		@seq.each{|bar|
			mtr = bar.mtr
			beat_dur = mtr.unit
			bar_dur = mtr.beat.sigma*beat_dur

			##### TUPLET #####
			bar.tpls.each.with_index{|tuple, tpl_id|
				tpp = tuple.par
				@dotted = [
					@dotDuplet!=nil,
					Math.log2(tpp.numer)%1==0,
					tpp.denom%3==0,
					note_value_dot(tpp)!=nil
				].all?

				##### NOTE #####
				tuple.evts.each.with_index{|evt, evt_id|
					_el = evt.el
					_du = evt.du

					@voice += "~ " if [_el]-%w(= =:)==[] || _el=~/==/
					close_bracket(tpl_id, evt_id)
					_el = add_tempo_mark(_el)
					add_time_signature(mtr, tpl_id)
					_el = add_grace_note(_el)

						@mainnote = ""

						# before main note
						%w(@ == r! s! R! rrr sss %+).each{|e|
							@mainnote += _el.sub(/#{e}.*/m, "") if _el=~/#{e.sub("+", "")}/
						}

						add_tuplet_bracket(tpp, evt_id)
						trem_nval = put_note(evt, tpp)
						add_note_value(evt, tpp, bar_dur)
						@mainnote += ":" if _el=="=:"

						# after main note
						%w(@ == r! s! R! rrr sss).each{|e|
							@mainnote += _el.sub(/.*#{e}/m, "") if _el=~/#{e}/
						}

						fingered_tremolo(evt, trem_nval) if _el=~/%/
					
					@voice += @mainnote
					add_beam(tuple, evt_id)

					@prev_dur = _du
					@prev_tpl = tpp
					@prev_elm = _el
					@voice += " "
				}
			}
		}

		# close voice
		@voice += "]" if @beaming
		@voice += "}" if @bracketing
		if @noMusBracket==nil
			@voice = "#{@namedMusic} = {#{@voice}\n}"
		end
		@voice
	end


	def textReplace(pattern, replacement)
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
		self.sequence
		s = self.scribe
		@output = do_gsub(s)
	end


	def print
		puts @output
	end


	def export(fname)
#		Dir::chdir(File.dirname(__FILE__))
		f = File.open(fname, 'w')
		n = File.absolute_path(fname)
		puts "exported > #{n}"
		f.puts @output
		f.close
	end
end

