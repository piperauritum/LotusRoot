﻿require_relative '_override'
require_relative '_notation'

class DataProcess
	include Notation


	def initialize(_tuplets)
		@tpl_param = _tuplets
	end


	def unfold_elements(dur, elm)
		if dur.select{|e| e<1}!=[]
			puts "LotusRoot >> Durations has wrong values #{dur.select{|e| e<1}}"
			raise
		end

		elm.map.with_index{|el, i|
			du = dur.on(i)
			if du>0
				case el
				when /@:/	# tremolo
					[el]+["=:"]*(du-1)

				when /@=/	# repeat markup on tied notes
					fo = el.sub("=", "")
					fo = fo.gsub(/#A(.*?)A#/m, "\\1")	# markup head
					la = el.sub("@", "=")
					la = la.gsub(/#A.*?A#/m, "")
					[fo]+[la]*(du-1)

				when /@/	# attack
					[el]+["="]*(du-1)

				when /(r!|s!|rrr|sss)/	# rest, spacer rest
					[el]+[$1]*(du-1)

				when /%/	# two-notes tremolo
					head = el.sub("%", "%ATK")
					rept = el.scan(/%\d+/)[0] + el.scan(/\[.+\]/)[0]
					[head]+[rept]*(du-1)

				when /=/	# tie
					[el]*du

				when Array	# staccato
					stacc_el, stacc_du = el
					if stacc_du > du
						puts "LotusRoot >> Staccato duration is longer than event duration."
						raise
					end
					sdu = [stacc_du, du].min-1
					rest = ["r!"]*(du-stacc_du)

					if stacc_el=~/@:/
						[stacc_el]+["=:"]*sdu+rest
					else
						[stacc_el]+["="]*sdu+rest
					end

				end
			end
		}.flatten
	end


	def process_metre(metre)
		begin
			metre = metre.map{|e|
				Fixnum===e ? [[e], 1] : e
			}

			metre = metre.map{|e|
				if e[0].size==1
					m = e[0][0]
					n = if m%3==0
						[3]*(m/3)
					else
						[2]*(m/2)+[m%2]-[0]
					end
					[n, e[1]]
				else
					e
				end
			}

			metre.map{|e| MtrParam.new(e)}
		rescue
			puts "LotusRoot >> .metre must be [Fixnum..] or [[[Fixnum..], Rational]..]"
			raise
		end	
	end


	def beat_structure(metre)
		begin
			metre.map{|e|
				if e.unit==1
					[1]*e.beat.sigma
				else
					e.beat.map{|f| e.unit*f}
				end
			}.flatten
		rescue
			puts "LotusRoot >> .metre must be [Fixnum..] or [[[Fixnum..], Rational]..]"
			raise
		end	
	end


	def assemble_tuplets(ary, tpl, metre)
		new_tpl = []
		new_ary = []
		beats = beat_structure(metre)
		idx = 0

		while ary.size>0
			begin
				tp = tpl.on(idx)
			rescue
				puts "LotusRoot >> Parameter of tuplet must be [Fixnum..] or [[Fixnum, Fixnum, Rational]..]"
				raise
			end

			beat = beats.on(idx)
			rept = 1

			case tp
			when Array
				tpp = tp.to_tpp
			when Fixnum
				tpp = tuplet_num_to_param(tp, beat)
				rto = Rational(tpp.numer, tpp.denom)
				if [
					!tpp.even?,
					tpp.numer>tp,
					tpp.numer!=rto.numerator,
					Rational(tp, rto.numerator)%1==0
				].all?
					if beat%1==0
						rept = tpp.numer/tp
						tpp = [tp, tpp.denom/rept, tpp.unit].to_tpp
					else
						rept = tpp.numer/rto.numerator
						tpp = [rto.numerator, rto.denominator, tpp.unit].to_tpp
					end
				end
			end

			rept.times{
				begin
					len = tpp.numer
					tick = tpp.tick
				rescue
					puts "LotusRoot >> Parameter of tuplet must be [Fixnum..] or [[Fixnum, Fixnum, Rational]..]"
					raise
				end

tu = Tuplet.new

				if Fixnum===tp && tick.numerator>1
					len = tp
					tick *= Rational(tpp.numer, tp)
				end

				if note_value(tpp)[tick]==nil
					puts <<-EOS

LotusRoot >> There is not notation of the duration (#{tick}) for tuplet (#{tpp.ar})
LotusRoot >> Beat: (#{beat})
LotusRoot >> #{note_value(tpp.ar)}
					EOS
					raise
				end

				# Cut tuplet out from array
				if ary.size>len
					ay = ary.slice!(0, len)
				else
					ay = ary.slice!(0, ary.size)
					ay += Array.new(len-ay.size, "r!")
				end

				# Simplify tuplet
				only_rest = ay-["r!"]==[]
				only_tie = ay-%w(= =:)==[]
				only_trem = ay.map{|e| !!(e=~/%\d+/)}.all?
				atk_tie = !!(ay[0]=~/@/) && ay[1..-1]-%w(= =:)==[]
				atk_trem = !!(ay[0]=~/%ATK/) && ay[1..-1].map{|e| !!(e=~/%\d+/)}.all?
				atk_mktie = (!!(ay[0]=~/@/) || !!(ay[0]=~/==/)) && ay[1..-1].map{|e| !!(e=~/==/)}.all?

				if [only_rest, only_tie, only_trem, atk_tie, atk_trem, atk_mktie].any?
					du = tick*len
					tick = Rational(1, du.denominator)
					len = du.numerator
					ay = [ay[0]] + [ay[1]]*(len-1)
tu.par = [len, len, tick].to_tpp
#					new_tpl << [len, len, tick].to_tpp
				else
					if Fixnum === tp
tu.par = tpp
#						new_tpl << tpp
					else
tu.par = tpl.on(idx).to_tpp
#						new_tpl << tpl.on(idx).to_tpp
					end
				end

				ay = ay.map{|e| Event.new(e, tick)}
tu.ev = ay
#				new_ary << ay
new_ary << tu
			}
			idx += 1
		end

		new_ary
#		[new_ary.dup, new_tpl.dup]
	end


	def delete_ties_across_beats(ary)
		ary.map{|e|
			if e.ev[0].el=="=" && e.ev.map(&:el).uniq!=["="]
#			if e[0].el=="=" && e.look.transpose[0]-["="]!=[]
				re = true
#				e.map{|f|
				e.ev.map!{|f|
					case f.el
					when /@/
						re = false
						f
					when "="
						re ? Event.new("r!", f.du) : f
					else
						f
					end
				}
#			else
#				e
			end
			e
		}
	end


	def subdivide_tuplet(evts, prev, tick, tpp, subdiv=true)

		tuple = evts.ev
	tpp = evts.par
#		tuple = evts.deepcopy
		quad, evt = [], nil
		t = tuple.size
		beat_struc = [t]

		if subdiv
			if @dotDuplet
				beat_struc = [2]*(t/2)+[t%2]
			elsif t%3==0
				beat_struc = [3]*(t/3) if tpp.numer!=3
			else
				beat_struc = [4]*(t/4)+[t%4]
			end
		end
		beat_struc -= [0]

		sliced = []
		beat_struc.each{|e|
			sliced << tuple.shift(e)
		}

		sliced.each.with_index{|sl, j|
			qa = []
			sl.each_with_index{|ev, i|
				if i==0
					evt = ev
				else
#					isAtk = ev.el=~/(@|%ATK|rrr|sss)/
					isTie = [ev.el]-%w(= =:)==[]
					markedTie = (prev=~/@/ || prev=~/==/) && ev.el=~/==/
#					newRest = %w(r! s!).map{|e|
#						(!(prev=~/#{e}/) && ev.el=~/#{e}/) || ev.el=~/#{e}./
#					}.any?
					bothRests = %w(r! s!).map{|e|
						prev=~/#{e}/ && ev.el=="#{e}"
					}.any?
#					noNval = note_value(tpp)[evt.dsum+tick]==nil
					bothTrems = prev=~/%/ && ev.el=~/%/ && !(ev.el=~/%ATK/)

#					isTriplet = beat_struc.on(j)==3 
#					headIsAtk = sl[0].el=~/(@|%ATK|rrr|sss)/
#					restInComp = isTriplet && headIsAtk && bothRests

					if [isTie, bothTrems, bothRests, markedTie].any? # && !restInComp
						evt.du = [evt.du, tick]
					else
						qa << evt
						evt = ev
					end

=begin
					if [isAtk, newRest, noNval].any?
						qa << evt
						evt = ev
					elsif [isTie, bothTrems, bothRests, markedTie].any?
						evt.du = [evt.du, tick]
					end
=end
				end
				prev = Tuplet.new(ev.el, tpp)
#				prev = ev.el
			}

			qa << evt

			quad << qa

		}

		quad = Tuplet.new(quad, tpp)

		[quad, prev]
	end
 
 
	def recombine_tuplet(evts, tpp)
		quad = evts.ev
	tpp = evts.par
#		quad = evts.deepcopy 
		tick = tpp.tick
		beat_struc = quad.map{|e|
			(e.dlook.flatten.sigma/tick).to_i
		}

		if tpp.even?
			beat_struc = [tpp.numer].map{|e|
				if e%3==0
					[3]*(e/3)
				else
					[4]*(e/4)+[e%4]-[0]
				end
			}.flatten
		end

		tp_ary = [beat_struc, tpp.denom, tpp.unit].to_tpp

		while 0
			id = 0
			time = 0
			again = false
			boo = false

			while id<quad.size
				fo, la = quad[id], quad[id+1]

				if la!=nil
					fol, laf = fo.last, la.first
					nv = fol.dsum + laf.dsum
					if fo.size>1
						time += fo[0..-2].dtotal
						boo = true
					end

					if @dotDuplet && tpp.dot?
						nval = note_value_dot(tpp)[nv]
					else
						nval = note_value(tpp)[nv]
					end

					bothNotes = [
						[laf.el]-%w(= =:)==[] &&
						[
							fol.el=~/@/,
							fol.el=='+',
							[fol.el]-%w(= =:)==[]
						].any?, 
						[
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

					pos_table = {
						3 => {
							2 => [0, 1],
							3 => [0],
							6 => [0],
						},
						4 => {
							2 => [0, 1, 2],
							3 => [0, 1],
							4 => [0, 2],
							6 => [0, 2],
							8 => [0],
						},
					}

					npos = allowed_positions(tp_ary, pos_table, nv)

					if tpp.even? || [6,8].map{|e| tpp.numer==e }.any?
						if @tidyTuplet!=nil && npos.all?{|e| time!=e}
							nval = nil
						end
					end

					if (bothNotes || bothRests) && nval!=nil
						fol.du = [fol.du, laf.du]
						la.shift
						quad.delete_if{|e| e==[]}
						again = again || true
					end

					time -= fo[0..-2].dtotal if boo
					time += fo.dtotal
				end
				id += 1
			end
			break if again == false
		end

		Tuplet.new(quad.flatten!, tpp)
#		quad.flatten!
	end

end