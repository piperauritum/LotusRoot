﻿require_relative '_seqTuplets'
require_relative '_seqBars'
require_relative '_scribe'
include Notation

class Score < DataProcess
	include Notation
	attr_reader :output
	attr_writer :pitchShift, :metre, :finalBar, :namedMusic, :noMusBracket,
	:accMode, :autoChordAcc, :reptChordAcc, :altNoteName, :beamOverRest, :noTieAcrossBeat, # :pnoTrem,
	:fracTuplet, :tidyTuplet, :dotDuplet, :omitRest


	def initialize(_durations, _elements, _tuplets, _pitches)
		super(_tuplets)
		@tpl_data = unfold_elements(_durations, _elements)
		@pitch = _pitches-[nil]
		@namedMusic = "hoge"
		@metre = [4]
		@accMode, @pitchShift = 0, 0
		@gspat, @gsrep = [], []
		@omitRest = []
	end


	def sequence
		@pitch = pitch_shift(@pitch, @pitchShift)
		@tpl_data, @tpl_param = assemble_tuplets(@tpl_data, @tpl_param, @metre)
		@tpl_data = delete_ties_across_beats(@tpl_data) if @noTieAcrossBeat

		tuples = []
		idx = 0
		@tpl_data.inject("r!"){|past, tuple|
			tpp = @tpl_param[idx]
			tick = Rational(tpp.denom*tpp.unit, tuple.size)

			reduc = ->(tuplet){
				abbr = tpl_abbreviations(tpp)
				abbr.select!{|e| e.even?} if tpp.even?
				if abbr!=[]
					abbr.each{|ab|
						tk = ab.tick
						dur_map = tuplet.flatten.map{|e| e.dsum}
						if dur_map.map{|du|
							(du/tk)%1==0 && note_value(ab)[du]!=nil
						}.all?
							len = dur_map.map{|e| (e/tk).to_i}
							len = len.map{|e| [*1..e].inject([]){|s,f| s.size==0 ? s=[tk] : s=[s,tk] }}
							len.each_with_index{|e,i| tuplet[i].du = len[i]}
#						p tuplet.map{|e| e.map{|f| f.class}}
							tpp = @tpl_param[idx] = ab
						end
					}
				end
			}

			## _seqTuplets.rb ##
p tuple, tpp
x, y = subdivide_tuplet(tuple, past, tick, tpp, false)[0]
reduc.call(x)
p x, tpp
			sd_tuplet, past = subdivide_tuplet(x, past, tick, tpp)
			reduc.call(sd_tuplet)
			rc_tuplet = recombine_tuplet(sd_tuplet.deepcopy, tpp)
			reduc.call(rc_tuplet)
			tuples << rc_tuplet
			idx += 1
		}

		## _seqBars.rb ##
		bars = assemble_bars(tuples, @metre, @finalBar)
		@seq, @tpl_param = connect_beat(bars, @metre, @tpl_param)
		@seq = markup_tail(@seq)
		@seq = slur_over_tremolo(@seq)

		@seq = rest_dur(@seq, @tpl_param)

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
				tpp = @tpl_param.on(@tpp_id)
				@dotted = [
					@dotDuplet!=nil,
					TplParam === tpp,
					Math.log2(tpp.numer)%1==0,
					tpp.denom%3==0,
					note_value_dot(tpp)!=nil
				].all?

				##### NOTE #####
				tuple.each.with_index{|nte, nte_id|
					_el, _du = nte.ar

					@voice += "~ " if [_el]-%w(= =:)==[] || _el=~/==/
					close_bracket(nte_id, beat_id)
					_el = add_tempo_mark(_el)
					add_time_signature(beat_id, mtr)
					_el = add_grace_note(_el)

						@mainnote = ""

						# before main note
						%w(@ == r! s! rrr sss %+).each{|e|
							@mainnote += _el.sub(/#{e}.*/m, "") if _el=~/#{e.sub("+", "")}/
						}

						add_tuplet_bracket(tpp, nte_id)
						trem_nval = put_note(nte, tpp)
						add_note_value(nte, tpp, bar_dur)
						@mainnote += ":" if _el=="=:"

						# after main note
						%w(@ == r! s! rrr sss).each{|e|
							@mainnote += _el.sub(/.*#{e}/m, "") if _el=~/#{e}/
						}

						fingered_tremolo(nte, trem_nval) if _el=~/%/
					
					@voice += @mainnote
					add_beam(tuple, nte_id)

					@prev_dur = _du
					@prev_tpl = tpp
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

