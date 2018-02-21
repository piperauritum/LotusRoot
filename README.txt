LotusRoot (beta)

## Overview
An assistance program for musical composition on Ruby.
Generates LilyPond script from some numeric/string arrays.

## Requirement
Ruby 2.2 ~
https://www.ruby-lang.org
http://rubyinstaller.org/downloads (win)

LilyPond 2.18.2 ~
http://lilypond.org

Frescobaldi 2.18 ~ (recommended)
http://www.frescobaldi.org

## Usage
cd <path>\LotusRoot
ruby test_mess.rb
lilypond test.ly

## Reference

# Durations
dur = [a0, a1, a2, ...]		(cyclic sequence)
	a	duration (Fixnum)

# Elements
elm = [a0, a1, a2, ...]		(linear sequence)
	a	element (String)

		@				attack of note
		=				sustain of note (can not use for rest)
		r!				rest
		s!				invisible (spacer) rest
		rrr				individual rest
		sss				individual rest
		(cmd)@(cmd)		attack with LilyPond command
		@=(cmd)			repeats markup for each tied notes
		@=#A(cmd)A#		markup on the head of tied notes
		@=#Z(cmd)Z#		markup on the tail of tied notes
		@:32			tremolo in Nth notes
		=:				sustain of tremolo
		%32[(pch)]		fingered tremolo in Nth notes
		@TMP4;60;		tempo mark (note value; BPM;)
		@GRC32;4;		grace notes (note value; amount of notes;)
		["@", 1]		staccato (shortened note)

# Tuplets
tpl = [a0, a1, a2, ...]		(cyclic sequence)
	a	number of division (Fixnum)

		or

	a	[n, d, u]
		n	numerator (Fixnum)
		d	denominator (Fixnum)
		u	unit duration (Rational)

# Pitches
pch = [a0, a1, a2, ...]		(cyclic sequence)
	a	Fixnum/Float/Rational (single note)

		or

	a	[Fixnum/Float/Rational] (chord)

		Fixnum			chromatic scale
		Float/Rational	1/4-tone (n/2) or 1/8-tone (n/4)

# Initialize
sco = Score.new(dur, elm, tpl, pch)

# Generates LilyPond script
sco.gen

# Outputs to console
sco.print

# Exports to a textfile
sco.export("sco.txt")

# Options
sco.pitchShift = a
	a	transposition (Fixnum/Float/Rational)

sco.metre = [a0, a1, a2, ...]		(cyclic sequence)
	a	numerator of time signature (Fixnum)
		(denominator = 4)

		or

	a	[[b], u]
		b	beat structure ([Fixnum])
		u	unit duration (Rational)
		(e.g. [[2,2,1], 1/2r] => \time 5/8)

sco.finalBar = a
	a	the last bar number (Fixnum)

sco.namedMusic = a
	a	namedMusic (String)

sco.noMusBracket = 0
	Removes namedMusic bracket.

sco.accMode = a
	a	Fixnum
		0: sharp
		1: flat
		2: sharp, without 3/4-tones
		3: flat, without 3/4-tones

sco.autoChordAcc = a
	a	Fixnum
		0: Selects sharp or flat for each chromatic chords automatically, avoids imperfect unison
		1: Additionary, aligns the degrees of dyads

sco.reptChordAcc = a
	Repeats accidentals to the next chord.

	a	Fixnum
		0: 
		1: Except if the chord is immediately repeated

sco.altNoteName = [a0, a1, a2, ...]
	Replaces note-names.

	a	[p, n]
		p	pitch (Fixnum/Float/Rational)
		n	note-name (String)

sco.beamOverRest = a
	a	Fixnum
		0: Writes beams over rests
		1: Writes beams forcibly

sco.noTieAcrossBeat = 0
	Deletes ties across beats.

sco.fracTuplet = 0
	Writes tuplet numbers in fraction form.

sco.tidyTuplet = 0
	Grouping tuplets clearly.

sco.dotDuplet = 0
	Rewrites 2:3 tuplets into dotted duplets.

sco.omitRest = [a0, a1, a2, ...]
	Excludes rests of given note values.

	a	note value (Fixnum/Float/Rational)

sco.wholeBarRest = 0
	Writes whole bar rests.

sco.textReplace(p, r)
	Replaces the text.

	p	pattern (String/Regexp)
	r	replacement (String)

## Author

Takumi Ikeda

## Copyright

(c) 2016-2018 Takumi Ikeda
This software is released under the MIT License, see LICENSE.txt.