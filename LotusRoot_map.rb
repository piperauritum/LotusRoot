require_relative 'meta'

module Notation
	def note_value(tpl) 
 	def note_name(pc, acc=0)
	def auto_accmode(chord, mode)	
	def natural?(pc)	
	def pitch_shift(pch, sum)	
	def chk_range(pch, a, b)
	def look	
	def vtotal

class Event

class Score
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
		@seq = make_tuplet(@seq, @tpl)
		@seq = delete_syncop(@seq) if @noTie

		ary = []
		idx = 0
		@seq.inject("r!"){|past, tuple|
			tp = @tpl.on(idx)
			if Array===tp
				tick = Rational(PPQN*tp[2]*tp[1], tp[0])
			else
				tick = Rational(PPQN, tp)
			end
			quad, past = quad_event(tuple, past, tick)
			ary << connect_quad(quad, tuple.size)
		}

		@note = connect_beat(ary, @measure)
		slur_over_tremolo(@note)
	end

	
	def scribe		
		self.sequence

		@note.each.with_index{|bar, bar_id|
			bar.each.with_index{|tuple, tpl_id|				
 				tuple.each.with_index{|nte, nte_id|
				}
			}
		}
	end

	
	def unfold_element(dur, elem)
		# dur = [4]; elem = ["@"]
		# => ["@", "=", "=", "="]
	
	def make_tuplet(ary, tpl=0)
		# ary = ["@", "=", "=", "="]; tpl = [6]
		# => [["@", "=", "=", "=", "r!", "r!"]]
	
	def delete_syncop(seq)
	
	def quad_event(tuple, past, tick)
		# ["@", "@", "=", "=", "r!", "r!"]
		# => [[["@", (8/3)], ["@", (8/1)]], [["r!", (16/3)]]]
	
	def connect_quad(quad, dv)		
		# [[["@", (8/1)], ["r!", (8/3)]], [["r!", (16/3)]]]
		# => [["@", (8/1)], ["r!", (8/1)]]
	
	def mold_bar(ary_beat, measure)	
		# Grouping beats into measure
		# [[["@", (16/1)]], [["=", (16/1)]], [["=", (32/3)], ["r!", (16/3)]]]
		# => [[[["@", (16/1)]], [["=", (8/1)]]], [[["=", (32/3)], ["r!", (16/3)]], [["r!", (8/1)]]]]
		# Fit beat into measure, Compress duration on half-beats, Fill bar(s) by rests.

	def connect_beat(ary_beat, measure)
		# [[["@", (32/3)], ["@", (16/3)]], [["=", (16/1)]], [["=", (16/1)]], [["=", (16/3)], ["@", (32/3)]]]
		# => [[[["@", (32/3)], ["@", (16/3)]], [["=", (32/1)]], [["=", (16/3)], ["@", (32/3)]]]]

		bars = mold_bar(ary_beat, measure)
	end
	
	def slur_over_tremolo(seq)
	
	def add_replace(pattern, replacement)

	def do_gsub(txt)

	def gen
		s = self.scribe
		@output = do_gsub(s)
	end

	def print

	def export(fname)
