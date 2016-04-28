﻿def slur_over_tremolo(seq)
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


def close_bracket(nte_id, beat_id)
	if nte_id==0
		if @beaming
			@voice += "]"
			@beaming = false
		end

		if @bracketing
			@voice += "} "
			@bracketing = false
		end

		@voice += "\n" if beat_id==0
	end
end


def put_note_name(pc)
	if Array === pc && pc.size>1
		acc = @accMode
		acc = auto_accmode(pc, @accMode) if @autoAcc
		nn = pc.map{|e|
			n = note_name(e, acc, @altNoteName)
			n += "!" if @prev_pch.include?(e) && !natural?(e) && @chordAcc
			n
		}.join(' ')
		@prev_pch = pc
		nn = "<#{nn}>"
	else
		pc = pc[0] if Array === pc
		@prev_pch = [pc]
		nn = note_name(pc, @accMode, @altNoteName)
	end
	nn
end


def add_tempo_mark(_el)
	if /((TMP)(.*;))/ =~ _el
		x = $3.split(/;/)
		@voice += "\\tempo #{x[0]} = #{x[1]} "
		_el = _el.sub(/TMP.*;/, "")
	end
	_el
end


def add_time_signature(beat_id, mtr)
	if beat_id==0 && mtr!=@prev_mtr
		if Array === mtr
			nu = mtr[0].sigma
			de = (Rational(1, mtr[1])*4).to_i
			@voice += "\\time #{nu}/#{de} "
		else
			@voice += "\\time #{mtr}/4 "
		end
	end
	@prev_mtr = mtr
end


def add_grace_note(_el)
	if /((GRC)(.*;))/ =~ _el
		gval, gnum = $3.split(/;/).map(&:to_i)
		gtxt = ""
		gnum.times{|i|
			@pch_id += 1
			gtxt += put_note_name(@pitch.on(@pch_id))
			gtxt += "#{gval}" if i==0
			gtxt += " " if i<gnum-1
		}
		@voice += "\\acciaccatura {#{gtxt}} "
		_el = _el.sub(/GRC.*;/, "")
		@prev_dur = gval
	end
	_el
end
		
			
def add_tuplet_bracket(tp, nte_id)
	if nte_id==0 && !@bracketing
		if !@dotted && ((Fixnum===tp && Math.log2(tp)%1>0) || (Array===tp && tp[0]!=tp[1]))
			@bracketing = true
			tp_a = @tpl_param.on(@tpp_id)
			if Array === tp_a
				@mainnote += "\\fractpl " if @fracTuplet!=nil 	# see config.ly
				@mainnote += "\\tuplet #{tp_a[0]}/#{tp_a[1]} {"
			else
				den = 2**Math.log2(tp_a).to_i
				@mainnote += "\\tuplet #{tp_a}/#{den} {"
			end
		end
	end
end


def put_note(nte, tp)
	_el, _du = nte.ar
	case _el
	when /r!|rrr/
		@mainnote += "r"				# (whole bar rest should not be used)
	when /s!|sss/
		@mainnote += "s"
	else
		@pch_id += 1 if _el=~/@|%%/		# next pitch
		if _el=~/%/						# fingered tremolo
			/((%+)(C?)(\d+))/ =~ _el
			trem_dur = $4.to_i
			t = [*0..4].map{|e| 2**e*tp[0]}.select{|e| e<=16}.max
			tr_times = note_value(t).key((trem_dur/2).to_s)
			tr_times = (_du/tr_times).to_i
			@mainnote += "\\repeat tremolo #{tr_times} {"
			@mainnote += "\\change Staff = lower " if @pnoTrem
		else
			@mainnote += put_note_name(@pitch.on(@pch_id))
		end
	end
	trem_dur
end


def add_note_value(nte, tp, bar_dur)
	_el, _du = nte.ar
	if @dotted
		nv = note_value_dot(tp)[_du]
	else
		nv = note_value(tp)[_du]
	end

	if nv==nil
		if @dotted
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
		(@prev_dur!=_du || @prev_tpl!=tp || @prev_elm=~/%/) || 
		(_du==bar_dur && (_el=~/r!|s!/))
		)
		@mainnote += nv
	end
end


def fingered_tremolo(nte, trem_dur)
	_el = nte.el
	ta = @pitch.on(@pch_id)
	tr_txt = _el.sub(/.*%+C?\d+/, "")
	tr_dat = _el.scan(/\[.+\]/)[0]
	tr_note = tr_dat.gsub(/\[|\]|\s/, "").split(",").map{|e| e.to_f+@pitchShift}

	if !(Array===ta) && tr_note.size==1
		tr_abc = put_note_name([ta, tr_note[0]])
		tr_abc = tr_abc.gsub(/<|>/, "").split(" ")
	else
		tr_abc = [put_note_name(ta), put_note_name(tr_note)]
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

	@mainnote += tr_abc[0]
	@mainnote += trem_dur.to_s
	@mainnote += " \\change Staff = upper" if @pnoTrem
	@mainnote += tr_txt
end


def add_beam(tuple, nte_id)
	if @beam!=nil
		if nte_id==0
			n = nte_id
			bm = true
			elz = []

			while 0
				n_el, n_va = tuple[n].ar
				elz << n_el

				nv = note_value(@tpl_param.on(@tpp_id))[n_va]
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
			bm = false if @beaming==true

			if bm
				@voice += "["
				@beaming = true
			end
		end
	end
end