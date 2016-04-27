\include "micro.ly"

\layout {
  \context {
    \Staff
    \override Stem.stemlet-length = #0.75
    \override TrillSpanner #'bound-details #'right #'padding = #2
    \override Beam.auto-knee-gap = ##f
    \override Beam.damping = #5
    \override MultiMeasureRest.expand-limit = #2

    % microtone
    \override KeySignature.glyph-name-alist = \arrowGlyphs
    \override Accidental.glyph-name-alist = \arrowGlyphs
    \override AccidentalCautionary.glyph-name-alist = \arrowGlyphs
    \override TrillPitchAccidental.glyph-name-alist = \arrowGlyphs
    \override AmbitusAccidental.glyph-name-alist = \arrowGlyphs
  }
}

fractpl = {
  \once \override TupletNumber.text = #tuplet-number::calc-fraction-text
}