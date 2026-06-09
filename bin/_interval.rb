require_relative '_notation'

# Interval naming and pitch spelling utilities.
# spellPitch() resolves enharmonic ambiguity by preferring major/minor/perfect
# intervals over augmented/diminished, matching the intonation intuition of singers.
#
# spellPitch(pch, 0) — greedy: optimises each note against the previous note
# spellPitch(pch, 1) — Viterbi DP: globally optimal spelling across the sequence
# spellPitch(pch, 2) — Viterbi DP + min2 forced for semitone steps (recommended)

module Notation

	DIA = %w(c d e f g a b)
	PCD = [2,2,1,2,2,2,1].itv_pch[0..-2]

	def nam_deg(na)
		x = DIA.index(na[0])
		if na.count(",'") > 0
			na.count(",").times{ x -= 7 }
			na.count("'").times{ x += 7 }
		end
		x
	end

	def nam_pch(na)
		x = PCD[nam_deg(na) % 7]
		x += 1 if na =~ /is/
		x -= 1 if na =~ /es/
		if na.count(",'") > 0
			na.count(",").times{ x -= 12 }
			na.count("'").times{ x += 12 }
		end
		x
	end

	def itvName(nn)   # [notename, notename]
		dx = nn.map{|e| nam_deg(e)}
		px = nn.map{|e| nam_pch(e)}

		deg = (dx[0] - dx[1]).abs
		itv = (px[0] - px[1]).abs
		cen = PCD[deg % 7]
		cen += deg / 7 * 12
		dif = itv - cen

		case deg % 7 + 1
		when 1, 4, 5
			itq = %w(dd dim P Aug AA)[dif + 2]
		else
			itq = %w(dd dim min Maj Aug AA)[dif + 3]
		end

		"#{itq}#{deg + 1}"
	end

	# Dispatcher:
	#   mode 0 — greedy, min2 preferred for semitone steps
	#   mode 1 — Viterbi DP, globally optimal (semitone ties break to sharps)
	#   mode 2 — Viterbi DP + min2 forced for semitone steps (recommended)
	def spellPitch(pch, mode = 0)
		case mode
		when 0 then spell_greedy(pch)
		when 1 then spell_viterbi(pch)
		when 2 then spell_viterbi(pch, force_min2: true)
		end
	end

	private

	# Score an interval name: 2=good (P/Maj/min), 1=tritone, 0=other Aug/dim
	def itv_score(name)
		case name
		when /^(P|Maj|min)/ then 2
		when /^(Aug4|dim5)/  then 1
		else                      0
		end
	end

	# mode 0: greedy — choose each note's spelling based on the previous note only
	def spell_greedy(pch)
		pcx = []
		prev_nn = nil
		prev_pc = nil

		pch.each{|pc|
			ac = [3, 8, 10].index(pc % 12) == nil ? 0 : 1   # ees, aes, bes

			if prev_nn != nil
				iv = (prev_pc - pc).abs % 12
				nn = [0, 1].map{|e| note_name(pc, e)}
				inm = nn.map{|e| itvName([prev_nn.delete(",'"), e.delete(",'")])}

				if iv == 1
					# prefer min2 (diatonic step) over Aug1 (chromatic inflection)
					2.times{|i| ac = i if inm[i] == "min2" }
					unless inm.any?{|n| n == "min2"}
						ac = pc > prev_pc ? 0 : 1  # fallback: direction-based
					end
				elsif iv == 6
					ascending = pc > prev_pc
					2.times{|i|
						ac = i if ascending ? inm[i] =~ /Aug4/ : inm[i] =~ /dim5/
					}
				else
					2.times{|i|
						ac = i if inm[i] =~ /min|P|Maj/
					}
				end
			end

			pcx << Complex(pc, ac)
			nn = note_name(pc, ac)
			# puts "#{prev_nn} #{nn} (#{iv}) #{itvName([prev_nn, nn])}" if prev_nn != nil
			prev_nn = nn
			prev_pc = pc
		}
		pcx
	end

	# mode 1/2: Viterbi DP — globally optimal spelling across the whole sequence
	# force_min2: for semitone transitions (iv==1 ascending, iv==11 descending), override scoring to prefer min2 over Aug1
	def spell_viterbi(pch, force_min2: false)
		n = pch.size
		return [] if n == 0

		dp   = Array.new(n){ [0, 0] }   # dp[i][ac] = best cumulative score
		from = Array.new(n){ [0, 0] }   # from[i][ac] = best previous ac

		# forward pass
		(1...n).each{|i|
			iv = (pch[i-1] - pch[i]).abs % 12
			[0, 1].each{|ac|
				nn_cur = note_name(pch[i], ac).delete(",'")
				best_score = -999
				best_prev  = 0
				[0, 1].each{|prev_ac|
					nn_prev = note_name(pch[i-1], prev_ac).delete(",'")
					name  = itvName([nn_prev, nn_cur])
					# iv==1: ascending semitone, iv==11: descending semitone (abs pitch)
					# +101 vs -100 (asymmetric) breaks ties in favour of earlier min2
					base  = if force_min2 && [1, 11].include?(iv)
						name == "min2" ? 101 : (name == "Aug1" ? -100 : itv_score(name))
					else
						itv_score(name)
					end
					score = dp[i-1][prev_ac] + base
					if score > best_score
						best_score = score
						best_prev  = prev_ac
					end
				}
				dp[i][ac]   = best_score
				from[i][ac] = best_prev
			}
		}

		# backtrace
		path = Array.new(n)
		path[n-1] = dp[n-1][0] >= dp[n-1][1] ? 0 : 1
		(n-2).downto(0){|i| path[i] = from[i+1][path[i+1]] }

		result = pch.each_with_index.map{|pc, i| Complex(pc, path[i]) }
		force_min2 ? fix_semitone_aug1(pch, result) : result
	end

	# post-pass for mode 2: greedily fix remaining Aug1 on semitone transitions
	def fix_semitone_aug1(pch, pcx)
		prev_nn = nil
		pcx.each_with_index{|cpc, i|
			pc = cpc.real
			nn = note_name(cpc).delete(",'")
			if prev_nn && [1, 11].include?((pch[i-1] - pch[i]).abs % 12)
				if itvName([prev_nn, nn]) == "Aug1"
					other_ac  = 1 - cpc.imag
					other_nn  = note_name(pc, other_ac).delete(",'")
					pcx[i] = Complex(pc, other_ac) if itvName([prev_nn, other_nn]) == "min2"
					nn = note_name(pcx[i]).delete(",'")
				end
			end
			prev_nn = nn
		}
		pcx
	end

end
