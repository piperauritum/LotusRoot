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


def put_note_name(pc, _el=nil)
	if Array === pc && pc.size>1
		acc = @accMode
		acc = auto_accmode(pc, @accMode, @autoChordAcc) if @autoChordAcc
		nn = pc.map{|e|
			n = note_name(e, acc, @altNoteName)
			if @prev_pch.include?(e) && !natural?(e) && !(_el=~/=/)
				case @reptChordAcc
				when 0
					n += "!"
				when 1
					n += "!" if @prev_pch!=pc
				end
			end
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
		
			
def add_tuplet_bracket(tpp, nte_id)
	if nte_id==0 && !@bracketing
		if !@dotted && ((Fixnum===tpp && Math.log2(tpp)%1>0) || (TplParam===tpp && !tpp.even?))
			@bracketing = true
			tpp = @tpl_param.on(@tpp_id)
			if TplParam===tpp
				@mainnote += "\\fractpl " if @fracTuplet!=nil 	# see config.ly
				@mainnote += "\\tuplet #{tpp.numer}/#{tpp.denom} {"
			else
				den = 2**Math.log2(tpp).to_i
				@mainnote += "\\tuplet #{tpp}/#{den} {"
			end
		end
	end
end


def put_note(nte, tp)
#	_el, _du = nte.ar
	_el = nte.el
	_du = nte.dsum

	case _el
	when /r!|rrr/
		@mainnote += "r"		# (whole bar rest should not be used)
	when /s!|sss/
		@mainnote += "s"
	else
		@pch_id += 1 if _el=~/@|%ATK/		# next pitch
		if _el=~/%/							# fingered tremolo
			/(%(ATK)?(SOT)?(\d+))/ =~ _el
			trem_nval = $4.to_i
			trem_dur = Rational(8, trem_nval)			
			nval_dur = note_value(2**16).key(note_value(tp)[_du])
			tr_times = (nval_dur/trem_dur).to_i
			
			if tr_times==0
				puts "LotusRoot >> Note value is equal or shorter than fingered-tremolo notes (\\repeat tremolo 0)"
				raise
			end
			@mainnote += "\\repeat tremolo #{tr_times} {"
		#	@mainnote += "\\change Staff = lower " if @pnoTrem
		else
			@mainnote += put_note_name(@pitch.on(@pch_id), _el)
		end
	end
	trem_nval
end


def add_note_value(nte, tp, bar_dur)
#	_el, _du = nte.ar
	_el = nte.el
	_du = nte.dsum

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
LotusRoot >> #{nte.look}
LotusRoot >> #{vv}
		EOS
		raise msg
	end

	if !(_el=~/%/) # && (
#		(@prev_dur!=_du || @prev_tpl!=tp || @prev_elm=~/%/) || 
#		(_du==bar_dur && (_el=~/r!|s!/))
#		)
		@mainnote += nv
	end
end


def fingered_tremolo(nte, trem_nval)
	_el = nte.el
	main_pch = @pitch.on(@pch_id)	
	trem_cmd = _el.sub(/.*%(ATK)?(SOT)?\d+/, "")
	trem_pch = _el.scan(/\[.+\]/)[0]	
	nnum = trem_pch.gsub(/\[|\]|\s/, "").split(",").map{|e|	
		e.gsub(/\(|\)/, "").to_r+@pitchShift
	}

	if Numeric===main_pch && nnum.size==1
		tr_abc = put_note_name([main_pch, nnum[0]])
		tr_abc = tr_abc.gsub(/<|>/, "").split(" ")
	else
		tr_abc = [put_note_name(main_pch), put_note_name(nnum)]
	end
	trem_cmd = trem_cmd.sub(trem_pch, "")

	case _el
	when /%ATKSOT/
		trem_cmd = "#{trem_cmd} (#{tr_abc[1]}}"
	when /%SOT/
		trem_cmd = "#{trem_cmd} #{tr_abc[1]})}"
	when /%ATK/
		trem_cmd = "#{trem_cmd} (#{tr_abc[1]})}"
	else
		trem_cmd = "#{trem_cmd} #{tr_abc[1]}}"
	end

	@mainnote += tr_abc[0]
	@mainnote += trem_nval.to_s
#	@mainnote += " \\change Staff = upper" if @pnoTrem
	@mainnote += trem_cmd
end


def add_beam(tuple, nte_id)
	if @beamOverRest!=nil
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