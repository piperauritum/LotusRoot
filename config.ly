\include "micro.ly"

%%%% longer stem for tremolo
#(define (stem-stretch stem-tremolo-grob)
   (let ((flag-count (ly:grob-property stem-tremolo-grob 'flag-count)))
     (if (> flag-count 1) 1.5 0)))

#(define (longer-for-tremolo stem-grob)
   (let* (
           (stem-tremolo-grob (ly:grob-object stem-grob 'tremolo-flag))
           (plain-stem? (< (ly:grob-property stem-grob 'duration-log) 8))
           )
     (+ (ly:stem::calc-length stem-grob)
       (if (and (ly:grob? stem-tremolo-grob) plain-stem?)
           (stem-stretch stem-tremolo-grob) 0))))

%%%% flat tuplet bracket
#(define flat-brackets
   (lambda (grob)
     (let* ((pos (ly:tuplet-bracket::calc-positions grob))
            (dir (ly:grob-property grob 'direction))
            (y (if (= UP dir)
                   (max (car pos) (cdr pos))
                   (min (car pos) (cdr pos)))))
       (cons y y))))

%%%% tuplet numbers in fraction form
fractpl = {
  \once \override TupletNumber.text = #tuplet-number::calc-fraction-text
}

%%%% config
\layout {
  \context {
    \Staff
    \override Stem.details.beamed-lengths = #'(5 5 4)
    \override Stem.stemlet-length = #1.5	%% spacing bug
%    \override Stem.length = #longer-for-tremolo	%% Assertion failed (?)
    \override Beam.auto-knee-gap = ##f
    \override Beam.damping = #5
    \override Beam.beam-thickness = #0.7
    \override Beam.length-fraction = #1.4
    \override LedgerLineSpanner.length-fraction = #0.4
    \override LedgerLineSpanner.minimum-length-fraction = #0.4
    \override TrillSpanner.bound-details.right.padding = #2
    \override TupletBracket.bracket-visibility = ##t
    \override TupletBracket.padding = #2
    \override TupletBracket.positions = #flat-brackets
    \override MultiMeasureRest.expand-limit = #2
    \override VerticalAxisGroup.staff-staff-spacing =
    #'((basic-distance . 0)
       (minimum-distance . 0)
       (padding . 4)
       (stretchability . 0))

    % microtone
    \override KeySignature.glyph-name-alist = \arrowGlyphs
    \override Accidental.glyph-name-alist = \arrowGlyphs
    \override AccidentalCautionary.glyph-name-alist = \arrowGlyphs
    \override TrillPitchAccidental.glyph-name-alist = \arrowGlyphs
    \override AmbitusAccidental.glyph-name-alist = \arrowGlyphs
  }
}

config = {
  % Activate below if Gonville is installed.
  %{
  \override NoteHead #'font-family = #'gonville
  \override Accidental #'font-family = #'gonville
  \override DynamicText #'font-family = #'gonville
  \override TrillSpanner #'font-family = #'gonville
  %}
  \accidentalStyle neo-modern
  \override Accidental.hide-tied-accidental-after-break = ##t
  \set Staff.extraNatural = ##f
  \override Staff.DynamicLineSpanner.outside-staff-priority = #500
  \override TupletNumber.font-size = #0
  \override TupletNumber.font-series = #'bold
  \set tupletFullLength = ##t
  \override TupletBracket.full-length-to-extent = ##f
  \tupletUp
  \overrideTimeSignatureSettings	%% fix odd beaming
  4/4        % timeSignatureFraction
  1/4        % baseMomentFraction
  #'(1 1 1 1)    % beatStructure
  #'()       % beamExceptions
  \set subdivideBeams = ##t

  %% it breaks cross-staff stems.
  \override TupletBracket.outside-staff-priority = #500
}

