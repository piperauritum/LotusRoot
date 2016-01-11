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

%%%% Subdivided beams
% sco.subdiv = 0
% \set subdivideBeams = ##t

bsmX = {
  \set baseMoment = #(ly:make-moment 1/4)
  \set beatStructure = #'(1 1 1 1)
}
bsmY = {
  \set baseMoment = #(ly:make-moment 1/8) 
  \set beatStructure = #'(2 2 2 2)
}