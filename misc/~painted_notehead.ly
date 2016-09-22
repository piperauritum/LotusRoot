\version "2.18.2"

%%%%  colored notehead with outline

coloredNoteHeads =
#(lambda (color-outline sha col)
   ;; @var{color-outline} is a boolean for whether
   ;; the outline is colored (#t) or the note head (#f).

   (lambda (grob)
     (let* (
             (fsz  (ly:grob-property grob 'font-size 0.0))
             (mult (magstep fsz))
             (stcl empty-stencil)
             (dur-log (ly:grob-property grob 'duration-log))
             (clr
              (case col
                ((0) (rgb-color 1 0 0))
                ((1) (rgb-color 1 .7 0))
                ((2) (rgb-color 1 1 0))
                ((3) (rgb-color 0 1 0))
                ((4) (rgb-color 0 1 1))
                ((5) (rgb-color .8 .8 .8))
                )
              )
             (ntc
              (rgb-color 0 0 0)
              )
             (outline-clr (if color-outline clr ntc))
             (note-clr (if color-outline ntc clr))
             (fct 0.1)
             (shape
              (cond
               ((> dur-log 1) ;; quarter notes and smaller
                 (case sha
                   ((0) "noteheads.s2cross")
                   ((1) "noteheads.u2triangle")
                   ((2) "noteheads.s2")
                   ))
               ((= dur-log 1) ;; half notes
                 (case sha
                   ((0) "noteheads.s2xcircle")
                   ((1) "noteheads.u1triangle")
                   ((2) "noteheads.s1")
                   ))
               ((= dur-log 0) ;; whole notes
                 (case sha
                   ((0) "noteheads.s2xcircle")
                   ((1) "noteheads.s0triangle")
                   ((2) "noteheads.s0")
                   ))
               ((< dur-log 0) ;; breve notes (NG)
                 (case sha
                   ((0) "noteheads.s2xcircle")
                   ((1) "noteheads.s0triangle")
                   ((2) "noteheads.sM1")
                   ))
               )
              )
             )

       (set! stcl
             (grob-interpret-markup grob
               #{
                 \markup {
                   \combine
                   \with-color #outline-clr
                   \translate-scaled #(cons fct 0)
                   \musicglyph #shape

                   \combine
                   \with-color #outline-clr
                   \translate-scaled #(cons (* -1 fct) 0)
                   \musicglyph #shape

                   \combine
                   \with-color #outline-clr
                   \translate-scaled #(cons 0 (* -1 fct))
                   \musicglyph #shape

                   \combine
                   \with-color #outline-clr
                   \translate-scaled #(cons 0 fct)
                   \musicglyph #shape

                   \with-color #note-clr
                   \musicglyph #shape
                 }
               #}
               )
             )

       (set! (ly:grob-property grob 'stencil)
             (ly:stencil-scale stcl mult mult)))))


col = #(define-music-function (parser location dat)
         (pair?)
         (define num (car dat))
         (define col (cdr dat))
         #{
           \override NoteHead.before-line-breaking = #(coloredNoteHeads #f num col)
         #}
         )

music =
\transpose c c' {
  \time 4/4
  c8 g d' a'
  c4 g d' a'
  c2 g d' a'1
  \time 2/1
  c\breve
}

\new Staff
{
  \col #'(0 . 0)
  \music
}
\new Staff
{
  \col #'(1 . 1)
  \music
}
\new Staff
{
  \col #'(2 . 2)
  \music
}
\new Staff
{
  \col #'(0 . 3)
  \music
}
\new Staff
{
  \col #'(1 . 4)
  \music
}
\new Staff
{
  \col #'(2 . 5)
  \music
}