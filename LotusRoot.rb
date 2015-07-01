require_relative 'meta'


module Notation
	TDIV = [12, 8, 10, 14]		# 32th notes in tuplet
	TPQN = TDIV.inject(:lcm)	# ticks per quarter Note
		

	def notevalue
		mul = [1, 2, 3, 4, 6, 8, 12, 16, 24, 32]
		val = ["32", "16", "16.", "8", "8.", "4", "4.", "2", "2.", "1"]
		TDIV.map{|d|
			ary = mul.zip(val).map{|m,v|
				m<d || d==8 ? [TPQN/d*m, v] : 0}
			ary -= [0]
			ary += [[TPQN, "4"]]
			Hash[*ary.uniq.flatten]
		}
	end
	
	
	def notename(x, acc=0)
		nname = [
			["c", "cis", "d", "dis", "e", "f", "fis", "g", "gis", "a", "ais", "b"],
			["c", "des", "d", "ees", "e", "f", "ges", "g", "aes", "a", "bes", "b"],
		]
		qname = ["cih", "deh", "dih", "eeh", "feh", "fih", "geh", "gih", "aeh", "aih", "beh", "ceh"]
		ename = ["ci", "cise", "cisi", "de", "di", "dise", "eesi", "ee", "ei", "fe", "fi", "fise",
				"fisi", "ge", "gi", "gise", "gisi", "ae", "ai", "aise", "besi", "be", "bi", "ce"]

		if x%1 == 0.5
			na = qname[(x%12).to_i]
		elsif x%0.5 == 0.25
			na = ename[(x%12-0.25)*2]
		else
			na = nname[acc][x%12]
		end

		otv = (x/12.0).floor
		otv += 1 if na == "ceh" || na == "ce"
		otv.abs.times{
			x>0 ? na+="'" : na+=","
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
	
	
	def pitch_shift(pch, sum)
		pch.mdadd(sum)
	end
	
	
	def chk_range(pch, a, b)
		pcs = pch.map{|e| Array===e ? e : [e]}-[[nil]]
		ans = true
		pcs.each{|e|
			range = [a, b]
			if e.max > range.max
				puts "out of upper limit: #{e}"
				ans = false
			elsif e.min < range.min
				puts "out of lower limit: #{e}"
				ans = false
			end		
		}
		ans
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
#	attr_reader :dur, :elem, :tpl, :pch, :sco, :seq, :note
	attr_reader :output
	attr_writer :instName, :measure, :pchShift, :accMode, :autoAcc, :beam, :noTie, :redTupRule, :pnoTrem	# , :minim, :minimBeam


	def initialize(_dur, _elm, _tpl, _pch)
		@seq = unfold(_dur, _elm)
		@tpl = _tpl
		@pch = _pch-[nil]
		@instName = "hoge"
		@measure = [4]
		@accMode, @pchShift = 0, 0
		@autoAcc, @beam, @pnoTrem, @redTupRule = [nil]*4
#		@autoAcc, @beam, @minim, @minimBeam, @pnoTrem, @redTupRule = [nil]*6
		@gspat, @gsrep = [], []
	end


	def sequence
		@pch = pitch_shift(@pch, @pchShift)
		@tpl = reduceTupl(@measure, @seq, @tpl, &@redTupRule)
		@seq = to_tuplet(@seq, @tpl)
		@seq = noSyncop(@seq) if @noTie

		ary = []
		@seq.inject("r!"){|past, tuple|
			tick = TPQN/tuple.size			
			quad, past = sliced_tuplet(tuple, past, tick)
			dv = [nil, 1, 1, 0, 1, 2, 0, 3, 1].at(tuple.size)
			ary << join_sliced(quad, dv)
		}

		@note = join_beat(ary, @measure)

	end

	
	def scoly		
		self.sequence

		pc_id = -1
		tick, pre_du = 0, nil
		pre_el = nil
		pre_tm = nil
		tp, pre_tp, tp_id = nil, nil, -1
		brac, beam_ed = nil, nil
		
		sco = "{"

		@note.each.with_index{|bar, bar_id|
			tm = @measure[bar_id % @measure.size]
			if Array===tm
				beatDur = TPQN/tm[1]
				barDur = tm[0].sigma*beatDur
			else
				beatDur = TPQN
				barDur = tm*beatDur
			end
		
			bar.each.with_index{|tuple, tpl_id|				
		
				# tuplet number
				tar = tuple.map{|e| e.ar}.transpose[1]
				tg = tar.inject(:gcd)
				tnum = tar.map{|e| e/tg}.sigma
				tp = [nil, 1, 1, 0, 1, 2, 0, 3, 1].at(tnum)
				tp = 1 if tar.sigma>TPQN

				tuple.each.with_index{|nte, nte_id|
					_el, _du = nte.ar
					wriDu = _du
					
					engrv = ->(pc){
						if Array === pc && pc.size>1
							acmd = @accMode
							acmd = auto_accmode(pc, @accMode) if @autoAcc							
							eg = pc.map{|e| notename(e, acmd)}.join(' ')
							eg = "<" + eg + ">"
						else
							pc = pc[0] if Array === pc
							eg = notename(pc, @accMode)
						end
					}

					# tie
					sco += "~ " if [_el]-["=","=:"]==[]

					# when on-beat				
					if nte_id==0					

						# close beam
						beam_ed -= 1 if beam_ed
						if beam_ed==0
							sco += "]"
							beam_ed = nil
						end

						# close bracket
						brac -= 1 if brac
						if brac==0
							sco += "} "
							brac = nil
						end
						
						# line break
						sco += "\n" if tpl_id==0
					end
					
					# tempo mark
					if /((TMP)(.*;))/ =~ _el
						x = $3.split(/;/)
						sco += "\\tempo #{x[0]} = #{x[1]} "
						_el = _el.sub(/TMP.*;/, "")
					end
					
					# time signature
					if tpl_id==0 && tm!=pre_tm
						if Array === tm
							sco += "\\time #{tm[0].sigma}/#{4*tm[1]} "
						else
							sco += "\\time #{tm}/4 "
						end
					end
					pre_tm = tm
					
					# grace note
					if /((GRC)(.*;))/ =~ _el
						gval, gnum = $3.split(/;/).map(&:to_i)
						sco += "\\acciaccatura {"
						gnum.times{|i|
							pc_id += 1
							pc_id %= @pch.size							
							sco += engrv.call(@pch[pc_id])
							sco += "#{gval}" if i==0
							sco += " "
						}
						sco += "} "
						_el = _el.sub(/GRC.*;/, "")
						pre_du = gval
					end

					# before note
					["@", "r!", "s!", "%+"].each{|e|
						sco += _el.sub(/#{e}.*/m,'') if _el=~/#{e.sub("+",'')}/
					}

					# tuplet bracket
					if nte_id==0
						case tp
						when 0
							tnum==3 ? sco += "\\tuplet 3/2 {" : sco += "\\tuplet 6/4 {"
						when 2
							sco += "\\tuplet 5/4 {"
						when 3
							sco += "\\tuplet 7/4 {"
						end
						brac = 1 if tp!=1 && brac==nil	
					end

					# putting note
					if _el=~/r!/
						wriDu==barDur ? sco+="R" : sco+="r"
						
					elsif _el=~/s!/
						sco+="s"
						
					else
						if _el=~/@/ || _el=~/%%/	# next pitch
							pc_id += 1
							pc_id %= @pch.size
						end

						if _el=~/%/		# two-notes tremolo
							/((%+)(\d+))/ =~ _el
							tremDur = $3.to_i
							tremTimes = notevalue[tp].key((tremDur/2).to_s)
#							@minim ? dx=_du/2 : dx=_du
							tremTimes = _du/tremTimes
							sco += "\\repeat tremolo #{tremTimes} {"
							sco += "\\lhStaff " if @pnoTrem
						end

						sco += engrv.call(@pch[pc_id])
					end

					# note value
					if !(_el=~/%/) && ((pre_du!=_du || pre_tp!=tp || pre_el=~/%/) || (wriDu==barDur && (_el=~/r!|s!/)))
						sco += notevalue[tp][wriDu]
					end
					
					# tremolo
					sco += ":" if _el=="=:"

					# after note
					["@", "r!", "s!"].each{|e|
						sco += _el.sub(/.*#{e}/m,'') if _el=~/#{e}/
					}

					# two-notes tremolo
					if _el=~/%/
						sco += tremDur.to_s
						sco += " \\rhStaff" if @pnoTrem
						tremSco = _el.sub(/.*%+\d+/,'')
						tremDat = _el.scan(/\[.+\]/)[0]
						tremNote = tremDat.gsub(/\[|\]|\s/,"").split(",").map{|e| e.to_f+@pchShift}
						tremWri = engrv.call(tremNote)					
						tremSco = tremSco.sub(tremDat, tremWri) + "}"
						sco += tremSco
					end

					# beam
					if @beam!=nil
						if nte_id==0
						
#					if @beam!=nil || @minimBeam!=nil
#						if (tick%beatDur==0 && !@minimBeam) ||
#						(tick%240==0 && @minimBeam)
					
							n = nte_id
							bea, foo = true, true
							dsum = 0
							elz = []
							
							while foo
								nE, nD = tuple[n].ar
								elz << nE

								# when the beam will be broken
#								@minimBeam ? dx=nD/2 : dx=nD
	
								q = notevalue[tp][nD]
								["4","2","1"].each{|e|
									bea = false if q!=nil && q.gsub(".","") == e
								}
								dsum += nD
								n += 1

								# search forward
								foo = false if n==bar.size || dsum%beatDur==0
								
#								foo = false if n==bar.size ||
#								(dsum%beatDur==0 && !@minimBeam) ||
#								(dsum%240==0 && @minimBeam)
							end

							# there is only the first note
							eq = elz.map{|e| e=~/@/ ? 1 : 0 }
							bea = false if eq[0]==1 && (eq-[0]).size==1

							# there is no rest
							eq = elz.map{|e| e=~/r!|s!/ ? 1 : 0 }
							bea = false if eq.sigma==0

							# rest only
							eq = elz.map{|e| e=~/r!|s!/ ? 0 : 1 }
							bea = false if eq.sigma==0
							
							# already beamed
							bea = false if beam_ed!=nil

							if bea
								sco += "["
								beam_ed = 1
#								@minimBeam && tick%240==0 ? beam_ed=2 : beam_ed=1
							end
						end
					end

					tick += _du
					pre_du = _du
					pre_tp = tp
					pre_el = _el
					sco += " "
				}
			}
		}

		sco += "]" if beam_ed
		sco += "}" if brac
		sco += "\n}"
		"#{@instName} = " + sco
	end

	
	def unfold(dur, elem)
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

				when /r!/			# rest
					du.times{ ary << el }
					
				when /s!/			# spacer rest
					ary << el
					(du-1).times{ ary << "s!" }
					
				when /%/			# two-notes tremolo
					ary << el.sub("%", "%%")
					(du-1).times{ ary << el.scan(/%\d+/)[0] + el.scan(/\[.+\]/)[0] }

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

	
	def to_tuplet(ary, tpl=0)
		# ary = ["@", "=", "=", "="]; tpl = [6]
		# => [["@", "=", "=", "=", "r!", "r!"]]

		if Array === tpl
			arx = []
			id = 0
			while ary.size>0
				if ary.size>tpl[id]
					arx << ary.slice!(0, tpl[id])
				else
					ay = ary.slice!(0, ary.size)
					ay += Array.new(tpl[id]-ay.size, "r!")
					arx << ay
				end
				id += 1
				id %= tpl.size
			end
			ary = arx.dup
		elsif tpl>0
			(tpl-ary.size%tpl).times{ ary << "r!" } if ary.size%tpl>0
			ary = ary.each_slice(tpl).to_a
		end
		ary
	end

	
	def sliced_tuplet(tuple, past, tick)
		# ["@", "=", "=", "=", "r!", "r!"]
		# => [[[#<Event:0x~~ @el="@", @va=80>], [#<Event:0x~~ @el="r!", @va=40>]], "r!"]
	
		quad, evt = [], nil
		sliced = tuple.each_slice(4).to_a
		sliced.each{|e|
			q = []
			e.each_with_index{|el, i|
				if i==0
					evt = Event.new(el, tick)
				else
					n_rest = ["r!", "s!"].map{|e|
						xelm = !(past=~/#{e}/) && el=~/#{e}/
						xadj =  past=~/#{e}/ && el=~/#{e}/ && past.sub(/#{e}/,'')!=el.sub(/#{e}/,'')
						xelm ? 1:0
#						xelm || xadj ? 1:0
					}.sigma>0					
					c_tie = [el]-["=","=:"]==[]					
					c_trem = past=~/%/ && el=~/%/ && !(el=~/%%/)					
					c_rest = ["r!", "s!"].map{|e| past=~/#{e}/ && el=~/#{e}/ ? 1:0 }.sigma>0
	
					if el=~/@/ || el=~/%%/ || n_rest					
						q << evt
						evt = Event.new(el, tick)
					elsif c_tie || c_trem || c_rest					
						evt.va += tick
					end
				end
				past = el
			}
			q << evt
			quad << q
		}
		[quad, past]
	end

	
	def join_sliced(quad, dv)		
		# This method can accept up to 8-plet.
		# 
		# [[#<Event:0x~~ @el="@", @va=80>], [#<Event:0x~~ @el="r!", @va=40>]]
		# => [#<Event:0x~~ @el="@", @va=80>, #<Event:0x~~ @el="r!", @va=40>]

		quad.each_with_index{|qu, i|
			if i!=quad.size-1
				fo = qu.last
				la = quad[i+1].first
								
				if ((fo.el=~/@/ || fo.el=='+' || [fo.el]-["=","=:"]==[]) && [la.el]-["=","=:"]==[]) ||
					(fo.el=~/r!/ && la.el=~/r!/) ||
					(fo.el=~/s!/ && la.el=~/s!/) ||
#					(fo.el=~/r!/ && la.el=~/r!/ && fo.el==la.el) ||
#					(fo.el=~/s!/ && la.el=~/s!/ && fo.el==la.el) ||
					(fo.el=~/%/ && la.el=~/%/ && !(la.el=~/%%/)) 
					
					fv = qu.map{|e| e.va}.inject(:gcd) == TPQN/8
					lv = quad[i+1].map{|e| e.va}.inject(:gcd) == TPQN/8
					
					if notevalue[dv][fo.va + la.va]!=nil &&	!(fv || lv)
						fo.va += la.va
						quad[i+1].shift
					end
				end
			end
		}
		quad.flatten!
	end

	
	def join_beat(ary_beat, measure)
		# [[#<Event:0x~~ @el="@", @va=120>], [#<Event:0x~~ @el="=", @va=60>, #<Event:0x~~ @el="r!", @va=60>]]
		# => [[["@", 180], ["r!", 60]]]

		m = 0
		bars = []
		while ary_beat.size>0
			meas = measure[m]
			
			if Fixnum === meas		# time N/4
				if ary_beat.size<meas
					(meas-ary_beat.size).times{
						ary_beat << [Event.new("r!", TPQN)]		# rest filling
					}
				end					
				bars << ary_beat.slice!(0, meas)
				
			else					# time N/8
				num = meas[0].size
				if ary_beat.size<num
					(num-ary_beat.size).times{
						ary_beat << [Event.new("r!", TPQN)]		# rest filling
					}
				end
				ar = ary_beat.slice!(0, num)
				ar = ar.map.with_index{|e,i|		# compress dur
					e.map{|f| Event.new(f.el, (f.va*Rational(meas[0][i], meas[1])).to_i)}
				}

				bars << ar
			end
			
			m += 1
			m %= measure.size
		end

		bars.each.with_index{|bar,i|
			time = measure[i%measure.size]
			time = bar.size if Array === time
		
			beat_structure = []			
			while time>1
				a = [2]*(time/2)
				a << 1 if time%2==1
				beat_structure << a
				time = a.size
			end

			# join
			beat_structure.each{|bst|
				xx = []
				id = 0
				
				bst.each{|be|
					while id < bar.size
						fo, la = bar[id], bar[id+1]

						if la!=nil && be==2
							fof, fol = fo.first, fo.last
							laf, lal = la.first, la.last

							matchValue = notevalue[1][fol.va + laf.va]!=nil

							homoElem = [laf.el]-["=","=:"]==[] ||
								(fol.el=~/%/ && laf.el=~/%/ && !(laf.el=~/%%/) && (fo.size==1 || la.size==1)) ||
								(fol.el=~/r!/ && laf.el=="r!") ||
								(fol.el=~/s!/ && laf.el=="s!")
#								(fol.el=~/r!|s!/ && fol.el==laf.el )								
												
#							homoPlet = [15,24,40].map{|e|
#								fo.map{|f| f.va}.min%e==0 && la.map{|l| l.va}.min%e==0 ? 1 : 0
#							}.sigma>0

							dsqv = Proc.new{|x| x.map{|e| e.va}.inject(true){|cond,e| e%(TPQN/8)==0&&cond}}						
							homoPlet = dsqv.(fo) && dsqv.(la)

							comb = false
							if matchValue && homoElem && homoPlet
								duples = [1/2r,1,2].map{|e| (TPQN*e).to_i }
								if i==0
									comb = true if [fol.va]-duples==[] && [laf.va]-duples==[]
								else
									duples -= [TPQN/2]
									comb = true if [fol.va]-duples==[] && [laf.va]-duples==[]
								end								
							end
							
							if comb
								fol.va += laf.va
								la.shift						
								fola = fo + la
								xx << fola		
							else
								xx << fo
								xx << la
							end
						else
							xx << fo
						end
						id += be
					end
					}
				bar = xx.dup
			}
			bars[i] = bar.dup
		}
=begin
		# reduction the markup for rest
		pre = nil
		bars.each{|bar|
			bar.each{|tuple|
				tuple.each{|ev|
					mem = ev.el
					ev.el = "r!" if mem=~/r!/ && pre==mem
					pre = mem
				}
			}
		}
=end
		bars
	end

	
	def noSyncop(seq)
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

	
	def reduceTupl(measure, seq, tpls, &block)
		# reduce tuplets on shorter beat		
		i, j = 0, 0
		tp = []
		se = seq.dup
		me = measure.map{|e|
			Array === e ? e[0].map{|f| f.to_f/e[1]} : [1]*e
		}.flatten

		block = lambda{|num_tuplet, ratio| [num_tuplet*ratio, 1].max} if block==nil
		
		while se.size>0
			u = tpls[j]
			u = block.call(u, me[i]) if me[i]<1
			se.slice!(0, u)
			tp << u
			i += 1
			i %= me.size
			j += 1
			j %= tpls.size
		end

		raise "wrong tuplet (less than 1) => #{tp}" if tp.min<1
		tp
	end

	
	def newReplace(pattern, replacement)
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
		s = self.scoly
		@output = do_gsub(s)
	end


	def print
		puts @output
	end


	def export(fname)
		Dir::chdir(File.dirname(__FILE__))
		f = File.open(fname, 'w')
		n = File.absolute_path(fname)
		puts "exported > #{n}"	
		f.puts @output
		f.close		
	end
end

