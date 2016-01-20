LotusRoot (alpha)


## Overview

An experimental Ruby program for computer-aided composition, that generates LilyPond code from arrays.


## Requirement

Ruby 2.2
LilyPond 2.18.2
Frescobaldi 2.18 (recommended)


## Example

ruby xmpl.rb
lilypond xmpl.ly


## Usage

pch = [Fixnum/Float]		# Pitch (cyclic); Array = chord, .5 = 1/4 tone, .25 = 1/8 tone
dur = [Fixnum]				# Duration (acyclic)
tpl = [Fixnum]				# Tuplet (cyclic); Divide a quarter-note into 1 to 16
elm = [String]				# Element (acyclic). See below

elm = [
	"@", "=", "r!", "rrr"	# Note/Attack (next pitch), Tie (not for rest), Rest, Individual Rest
	["@", 1]				# Staccato
	"\\hoge @ \\moge",		# '@' w/ LilyPond command
	"@:N", "=:",			# Tremolo in Nth notes
	"%N[pch]",				# Two-notes tremolo (Nth)
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
sco.pchShift = 0			# Transposition
sco.accMode = 0				# 0, 1 = Sharp, Flat
sco.autoAcc = nil			# 0(!nil) = Auto select accidentals of chord
sco.chordAcc = nil			# 0 = Engrave accidentals to the chord regardless of last chord
sco.beam = nil				# 0 = Beam over rest on every quarter notes
sco.subdiv = nil			# 0 = \set baseMoment & beatStructure for subdivideBeams (experimental)
sco.pnoTrem = nil			# 0 = "\change Staff = upper" "\change Staff = lower"
sco.noTie = nil				# 0 = Remove syncopation (without a certain case)
sco.redTupRule = lambda{|num_tuplet, ratio| [num_tuplet*ratio, 1].max}
							# Rule of reducing tuplets on shorter beat
sco.finalBar = nil			# Last number of bars
sco.add_replace(pattern, replacement)	# Add new text replacement
ssco.noInstName = nil		# 0 = Output only notation
sco.gen						# Generate LilyPond code
sco.print					# Output to console
sco.export("sco.txt")		# Export


## Author

Takumi Ikeda


## Copyright

(C) Copyright 2015-2016 by Takumi Ikeda, All Rights Reserved.
No warranty.