require_relative '_sequence'
require_relative '_scribe'
include Notation

class Score < DataProcess
	include Notation
	attr_reader :output
	attr_writer :pitchShift, :metre, :finalBar, :namedMusic, :noMusBracket,
	:accMode, :autoChordAcc, :reptChordAcc, :altNoteName, :beamOverRest, :noTieAcrossBeat, # :pnoTrem,
	:fracTuplet, :tidyTuplet, :dotDuplet


	def initialize(_durations, _elements, _tuplets, _pitches)
		super(_tuplets)
		@tpl_data = unfold_elements(_durations, _elements)
		@pitch = _pitches-[nil]
		@namedMusic = "hoge"
		@metre = [4]
		@accMode, @pitchShift = 0, 0
		@gspat, @gsrep = [], []
	end


	def sequence
		@pitch = pitch_shift(@pitch, @pitchShift)
		@tpl_data, @tpl_param = assemble_tuplets(@tpl_data, @tpl_param, @metre)
		@tpl_data = delete_ties_across_beats(@tpl_data) if @noTieAcrossBeat
		
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
		@pch_id, @tpp_id = -1, 0
		@prev_pch = []
		@prev_dur, @prev_elm, @prev_tpl, @prev_mtr = [nil]*4
		@bracketing, @beaming = nil, nil
		@voice = ""

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
				tp = @tpl_param.on(@tpp_id)
				@dotted = [
					@dotDuplet!=nil,
					Array === tp,
					Math.log2(tp[0])%1==0,
					tp[1]%3==0,
					note_value_dot(tp)!=nil
				].all?

				##### NOTE #####
				tuple.each.with_index{|nte, nte_id|
					_el, _du = nte.ar

					@voice += "~ " if [_el]-%w(= =:)==[]
					close_bracket(nte_id, beat_id)
					_el = add_tempo_mark(_el)
					add_time_signature(beat_id, mtr)
					_el = add_grace_note(_el)

						@mainnote = ""

						# before main note
						%w(@ r! s! rrr sss %+).each{|e|
							@mainnote += _el.sub(/#{e}.*/m, "") if _el=~/#{e.sub("+", "")}/
						}

						add_tuplet_bracket(tp, nte_id)
						trem_nval = put_note(nte, tp)
						add_note_value(nte, tp, bar_dur)
						@mainnote += ":" if _el=="=:"

						# after main note
						%w(@ r! s! rrr sss).each{|e|
							@mainnote += _el.sub(/.*#{e}/m, "") if _el=~/#{e}/
						}

						fingered_tremolo(nte, trem_nval) if _el=~/%/
					
					@voice += @mainnote
					add_beam(tuple, nte_id)

					@prev_dur = _du
					@prev_tpl = tp
					@prev_elm = _el
					@voice += " "
				}
				@tpp_id += 1
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

