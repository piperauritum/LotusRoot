LotusRoot


## Overview

A LilyPond code generator for Ruby.
Converts pitch/duration data into LilyPond code.
(This is alpha version.)


## Requirement

Ruby 2.2
LilyPond 2.18.2
Frescobaldi 2.18 (recommended)


## Usage

ruby example.rb
lilypond example.ly


## Description

pch = [Fixnum/Float] (pitch)	# Array = chord, .5 = 1/4 tone, .25 = 1/8 tone
dur = [Fixnum] (duration)
tpl = [Fixnum] (tuplet)			# cyclic. over 8-tet are not supported yet
elm = [String] (element)		# (see below)

sco = Score.new(dur, elm, tpl, pch)
sco.instName = "hoge"
sco.measure = [4]				# cyclic (see below)
sco.pchShift = 0				# transposition
sco.accMode = 0					# 0, 1 = sharp, flat
sco.autoAcc = nil				# 0(!nil) = auto select accidentals of chord
sco.beam = nil					# 0 = beam over rest on every quarter notes
sco.noTie = nil					# 0 = remove syncopation (without a certain case)
sco.redTupRule = lambda{|q| 4-q%2}	# rule of reducing tuplets on 8th	
sco.export("sco.txt")

elm = [
	["@", "=", "r!"],					# tuplet[next, tie(not for rest), rest]
	["\\hoge @ \\moge"],				# '@' with LilyPond command
	["@:32", "=:"],						# tremolo
	["\\hoge %N \\moge [pcs] \\voge"],	# two-notes tremolo(Nth) with command
]

Score#measure = [
	N,				# N/4
	[[2,2,1], 2]	# (2+2+1)/8 = 5/8
					# Numerators must be 1 or 2. (Fraction is multipled to number of tuplet.)
]


## Author

Takumi Ikeda
https://bitbucket.org/piperauritum


## Copyright

(C) Copyright 2015 by Takumi Ikeda, All Rights Reserved.
No warranty.