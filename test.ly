\version "2.18.2"
\include "config.ly"
\include "sco.txt"

%#(set-global-staff-size 12)
%#(set-default-paper-size "a4" 'landscape)

\score {
  { 
    \set subdivideBeams = ##t
    \set Staff.extraNatural = ##f
    \accidentalStyle neo-modern
    \hoge
  }
  \layout {}
  \midi {}
}