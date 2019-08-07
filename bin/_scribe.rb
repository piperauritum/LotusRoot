def close_bracket(tpl_id, evt_id)
	if evt_id==0
		if @beaming
			@voice += "]"
			@beaming = false
		end

		if @bracketing
			@voice += "} "
			@bracketing = false
		end

		@voice += "\n" if tpl_id==0
	end
end


def put_note_name(pc, _el=nil)
	if Array === pc # && pc.size>1
		acc = @accMode
		acc = auto_accmode(pc, @accMode, @autoChordAcc) if @autoChordAcc
		del_prev_acc = []
		nn = pc.map{|e|
			n = note_name(e, acc, @altNoteName)
			if [!(_el=~/=/), !natural?(e), @last_pch.include?(e)].all?
				case @reptChordAcc
				when 0
					n += "!"
				when 1
					n += "!" if @last_pch!=pc
				end
			elsif [@distNat, !(_el=~/=/), natural?(e), @prev_acc.index(n)!=nil].all?
				del_prev_acc << n
				n += "!"
			end
			n
		}.join(' ')
		@last_pch = pc
		nn = "<#{nn}>"
		del_prev_acc.each{|e|
			@prev_acc -= [e]
		}
	else
#		pc = pc[0] if Array === pc
		@last_pch = [pc]
		nn = note_name(pc, @accMode, @altNoteName)

		if [@distNat, !(_el=~/=/), natural?(pc), @prev_acc.index(nn)!=nil].all?
			@prev_acc -= [nn]
			nn += "!"
		end
	end

	nx = nn.gsub(/[<>!]/, "").split(" ")
	nx.each{|e|
		oct = e.gsub(/[a-z]/, "")
		xoc = e.gsub(oct, "")
		nat = xoc[0]+oct

		if xoc.size>1 && @prev_acc.index(nat)==nil
			@prev_acc << nat
		end
	}

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


def add_time_signature(mtr, tpl_id)
	if tpl_id==0 && mtr.ar!=@prev_mtr
		nu = mtr.beat.sigma
		de = (Rational(1, mtr.unit)*4).to_i
		@voice += "\\time #{nu}/#{de} "
	end
	@prev_mtr = mtr.ar
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


def add_tuplet_bracket(tpp, evt_id)
	if evt_id==0 && !@bracketing
		if !@dotted && ((Integer===tpp && Math.log2(tpp)%1>0) || (TplParam===tpp && !tpp.even?))
			@bracketing = true

			if TplParam === tpp
				@mainnote += "\\fractpl " if @fracTuplet!=nil 		# see config.ly
				@mainnote += "\\tuplet #{tpp.numer}/#{tpp.denom} {"
			else
				den = 2**Math.log2(tpp).to_i
				@mainnote += "\\tuplet #{tpp}/#{den} {"
			end
		end
	end
end


def put_note(evt, tp)
	_el = evt.el
	_du = evt.dsum

	case _el
	when /R!/
		@mainnote += "R"
	when /r!|rrr/
		@mainnote += "r"
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
			@all_pch << @pitch.on(@pch_id) if _el=~/@/
		end
	end
	trem_nval
end


def add_note_value(evt, tpp, bar_dur)
	_el = evt.el
	_du = evt.dsum

	if @dotted
		nv = note_value_dot(tpp)[_du]
	else
		nv = note_value(tpp)[_du]
	end

	if nv==nil
		if evt.el=~/R!/
			unit = evt.dlook.flatten.min
			mul = (_du/unit).to_i
			if @dotted
				nv = note_value_dot(64)[unit]
			else
				nv = note_value(64)[unit]
			end
			raise if nv == nil
			nv = "#{nv}*#{mul}"
		else

			if @dotted
				vv = note_value_dot(tpp)
			else
				vv = note_value(tpp)
			end
			msg = <<-EOS

LotusRoot >> There is not notation of the duration (#{_du}) for tuplet (#{tpp.ar}).
LotusRoot >> #{evt.look}
LotusRoot >> #{vv}
			EOS
			raise msg
		end
	end

	if !(_el=~/%/) # && (
#		(@prev_dur!=_du || @prev_tpl!=tpp || @prev_elm=~/%/) || 
#		(_du==bar_dur && (_el=~/r!|s!/))
#		)
		@mainnote += nv
	end
end


def fingered_tremolo(evt, trem_nval)
	_el = evt.el
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


def add_beam(tuple, evt_id)
	if @beamOverRest!=nil
		if evt_id==0
			n = evt_id
			bm = true
			elz = []

			while 0
				n_el = tuple.evts[n].el
				n_va = tuple.evts[n].dsum
				elz << n_el

				nv = note_value(tuple.par)[n_va]
				qry = %w(4 2 1)
				qry = %w(2 1) if @dotDuplet!=nil
				qry.each{|e|
					bm = false if nv!=nil && nv.gsub(".", "")==e
				}
				n += 1

				# search forward
				break if n==tuple.evts.size
			end

			# only the first note
			eq = elz.map{|e| e=~/@/ ? 1 : 0 }
			bm = false if eq[0]==1 && (eq-[0]).size==1

			# no rest
			eq = elz.map{|e| e=~/r!|s!|rrr|sss/ ? 1 : 0 }.sigma
			bm = false if eq==0 && @beamOverRest==0

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