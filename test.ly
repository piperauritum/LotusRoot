\version "2.19.61"
\include "config.ly"
\include "micro.ly"
\include "sco.txt"

\header {
  tagline = ""
}

#(set-global-staff-size 16)
%#(set-default-paper-size "a4" 'landscape)

% Activate below if Gonville is installed.
% http://www.chiark.greenend.org.uk/~sgtatham/gonville/

%{
#(define-public (add-notation-font fontnode name music-str brace-str factor)
   (begin
    (add-music-fonts fontnode
      name music-str brace-str
      feta-design-size-mapping factor)
    fontnode))

\paper {
  #(define notation-fonts
     (list
      (list 'emmentaler "emmentaler" "emmentaler")
      (list 'gonville "gonville" "gonville")
      ))

  #(begin
    (for-each
     (lambda (tup)
       (add-notation-font fonts
         (car tup) ; font identifier
         (cadr tup) ; notation font
         (caddr tup) ; brace font
         (/ staff-height pt 20)))
     notation-fonts))
}
%}

\score {
  {
    \config
    \hoge
  }
  \layout {}
  \midi {}
}