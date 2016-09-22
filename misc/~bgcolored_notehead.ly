\version "2.18.2"

%%%%  background color

bgcol =
#(define-music-function (parser location num)
   (number?)
   #{
     \override NoteHead.stencil =
     $(lambda (grob)
        (let*
         (
           (col
            (case num
              ((0) (rgb-color 1 .4 .4))
              ((1) (rgb-color 1 .7 .3))
              ((2) (rgb-color 1 1 0))
              ((3) (rgb-color .5 1 .5))
              ((4) (rgb-color .6 1 1))
              ((5) (rgb-color .7 .7 .7))
              )
            )
           (note (ly:note-head::print grob))
           (X-ext 0.6)
           (Y-ext 1.2)
           (X-pos 0.5)
           (combo-stencil
            (ly:stencil-add
             (ly:stencil-translate-axis
              (ly:make-stencil
               (list 'color col
                 (ly:stencil-expr (make-circle-stencil X-ext Y-ext #t))
                 X-ext Y-ext)
               )
              X-pos 0)
             note)
            )
           )
         (ly:grob-set-property! grob 'layer -10)
         (ly:make-stencil
          (ly:stencil-expr combo-stencil)
          (ly:stencil-extent note X)
          (ly:stencil-extent note Y)
          )
         ))
   #})

music =
\transpose c c' {
  \bgcol #0 c8
  \bgcol #1 e8.
  \bgcol #2 gis
  \bgcol #3 c'8
  \bgcol #4 e'8.
  \bgcol #5 gis'
}

<<
  \new Staff {
    \music
    \override NoteHead.style = #'triangle
    \music
    \override NoteHead.style = #'cross
    \music
  }
>>