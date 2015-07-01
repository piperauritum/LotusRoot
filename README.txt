LotusRoot (alpha)


## Overview

A LilyPond code generator for Ruby.
Converts pitch/duration data into LilyPond code.


## Requirement

Ruby 2.2
LilyPond 2.18.2
Frescobaldi 2.18 (recommended)


## Usage

ruby example.rb
lilypond example.ly


## Description

pch = [Fixnum/Float]		# Pitch (cyclic). Array = chord, .5 = 1/4 tone, .25 = 1/8 tone
dur = [Fixnum]				# Duration (acyclic)
tpl = [Fixnum]				# Tuplet of quarter note (cyclic). Over 8-plet is not supported yet.
elm = [String]				# Element (acyclic). See below.

elm = [
	"@", "=", "r!",			# Note/Attack (next pitch), Tie (not for rest), Rest
	"\\hoge @ \\moge",		# '@' w/ LilyPond command
	"@:N", "=:",			# Tremolo in Nth
	"%N [pch]",				# Two-notes tremolo (Nth)
	"@TMP4;60;",			# Note w/ Tempo mark (note value; bpm;)
	"@GRC32;4;",			# Note w/ Grace notes (note value; number;)
]

sco = Score.new(dur, elm, tpl, pch)
sco.instName = "hoge"
sco.measure = [				# Time signature (cyclic)
	N,							# N/4
	[[2,2,1], 2],				# 5/8 = (2+2+1)/(4*2) Numerators must be 1 or 2.
	[[2,1], 4],					# 3/16 = (2+1)/(4*4)
]
sco.pchShift = 0			# Transposition.
sco.accMode = 0				# 0, 1 = Sharp, Flat
sco.autoAcc = nil			# 0(!nil) = Auto select accidentals of chord.
sco.beam = nil				# 0 = Beam over rest on every quarter notes.
sco.noTie = nil				# 0 = Remove syncopation (without a certain case).
sco.redTupRule = lambda{|num_tuplet, ratio| [num_tuplet*ratio, 1].max}
							# Rule of reducing tuplets on shorter beat.
sco.newReplace(pattern, replacement)	# Add new text replacement
sco.gen
sco.print
sco.export("sco.txt")


## Author

Takumi Ikeda


## Copyright

(C) Copyright 2015 by Takumi Ikeda, All Rights Reserved.
No warranty.