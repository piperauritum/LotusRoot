LotusRoot (beta)

## Overview
An assistance program for musical composition on Ruby.
Generates LilyPond script from some numeric/string arrays.

## Requirement
Ruby 2.4 or later
https://www.ruby-lang.org
http://rubyinstaller.org/downloads (win)

LilyPond 2.18.2 or later
http://lilypond.org

Frescobaldi 2.18 or later (recommended)
http://www.frescobaldi.org

## Usage
cd <path>\LotusRoot\doc
ruby test_mess.rb
lilypond test.ly

## Reference

# Durations
dur = [x0, x1, x2, ...]		(cyclic sequence)
	x	duration (Integer)

# Elements
elm = [x0, x1, x2, ...]		(linear sequence)
	x	element (String)

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
tpl = [x0, x1, x2, ...]		(cyclic sequence)
	x	number of division (Integer)

		or

	x	[n, d, u]
		n	numerator (Integer)
		d	denominator (Integer)
		u	unit duration (Rational)

# Pitches
pch = [x0, x1, x2, ...]		(cyclic sequence)
	x	Integer/Float/Rational/Complex (single note)

		or

	x	[Integer/Float/Rational/Complex] (chord)

		Integer			chromatic scale
		Float/Rational	1/4-tone (n/2) or 1/8-tone (n/4)
		Complex(b, c)	Specifies an accidental (experimental)
			b	single note
			c	accidental mode (see sco.accMode)

# Initialize
sco = Score.new(dur, elm, tpl, pch)

# Generates LilyPond script
sco.gen

# Outputs
x = sco.output
	x	LilyPond script

sco.print
	Outputs to console

x = sco.sc(tempo=60, synth="hoge")
	x	SuperCollider score (experimental)

# Exports to a textfile
sco.export(filename)

# Options
sco.config = x
	x	configuration in the beginning (String)

sco.pitchShift = x
	x	transposition (Integer/Float/Rational)

sco.metre = [x0, x1, x2, ...]		(cyclic sequence)
	x	numerator of time signature (Integer)
		(denominator = 4)

		or

	x	[[b], u]
		b	beat structure ([Integer])
		u	unit duration (Rational)
		(e.g. [[2,2,1], 1/2r] => \time 5/8)

sco.finalBar = x
	x	the last bar number (Integer)

sco.namedMusic = x
	x	namedMusic (String)

sco.noMusBracket = 0
	Removes namedMusic bracket.

sco.accMode = x
	x	Integer
		0: sharp
		1: flat
		2: sharp, without 3/4-tones
		3: flat, without 3/4-tones
		4: sharp + double sharp for "white key notes", chromatic scale only
		5: flat + double flat for "white key notes", chromatic scale only

sco.autoChordAcc = x
	x	Integer
		0: Selects sharp or flat for each chromatic chords automatically, avoids imperfect unison
		1: Additionary, aligns the degrees of dyads

sco.reptChordAcc = x
	Repeats accidentals to the next chord.

	x	Integer
		0:
		1: Except if the chord is immediately repeated

sco.distNat = 0
	Adds naturals regardless of bars, but ignores the octaves.

sco.altNoteName = [x0, x1, x2, ...]
	Replaces note-names.

	x	[p, n]
		p	pitch (Integer/Float/Rational)
		n	note-name (String)

sco.beamOverRest = x
	x	Integer
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

sco.splitBeat = 0
	Disable connecting of beats.

sco.avoidRest = [x0, x1, x2, ...]
	Excludes rests of given note values.

	x	note value (Integer/Float/Rational)

sco.wholeBarRest = 0
	Writes whole bar rests.

sco.textReplace(p, r)
	Replaces the text.

	p	pattern (String/Regexp)
	r	replacement (String)

## Author

Takumi Ikeda

## Copyright

(c) 2016-2019 Takumi Ikeda
This software is released under the MIT License, see LICENSE.txt.
