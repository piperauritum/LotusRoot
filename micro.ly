﻿%% \set Staff.extraNatural = ##f

%%%% eighth tone accidentals
#(define-public THREE-QUARTER-SHARP 3/4)
#(define-public SHARP-RAISE 5/8)
#(define-public SHARP-LOWER 3/8)
#(define-public QUARTER-SHARP 1/4)
#(define-public NATURAL-RAISE 1/8)
#(define-public NATURAL-LOWER -1/8)
#(define-public QUARTER-FLAT -1/4)
#(define-public FLAT-RAISE -3/8)
#(define-public FLAT-LOWER -5/8)
#(define-public THREE-QUARTER-FLAT -3/4)

arrowedPitchNames = #`(
                        (ceses . ,(ly:make-pitch -1 0 DOUBLE-FLAT))
                        (ceseh . ,(ly:make-pitch -1 0 THREE-QUARTER-FLAT))
                        (cese . ,(ly:make-pitch -1 0 FLAT-LOWER))
                        (ces . ,(ly:make-pitch -1 0 FLAT))
                        (cesi . ,(ly:make-pitch -1 0 FLAT-RAISE))
                        (ceh . ,(ly:make-pitch -1 0 QUARTER-FLAT))
                        (ce . ,(ly:make-pitch -1 0 NATURAL-LOWER))
                        (c . ,(ly:make-pitch -1 0 NATURAL))
                        (ci . ,(ly:make-pitch -1 0 NATURAL-RAISE))
                        (cih . ,(ly:make-pitch -1 0 QUARTER-SHARP))
                        (cise . ,(ly:make-pitch -1 0 SHARP-LOWER))
                        (cis . ,(ly:make-pitch -1 0 SHARP))
                        (cisi . ,(ly:make-pitch -1 0 SHARP-RAISE))
                        (cisih . ,(ly:make-pitch -1 0 THREE-QUARTER-SHARP))
                        (cisis . ,(ly:make-pitch -1 0 DOUBLE-SHARP))

                        (deses . ,(ly:make-pitch -1 1 DOUBLE-FLAT))
                        (deseh . ,(ly:make-pitch -1 1 THREE-QUARTER-FLAT))
                        (dese . ,(ly:make-pitch -1 1 FLAT-LOWER))
                        (des . ,(ly:make-pitch -1 1 FLAT))
                        (desi . ,(ly:make-pitch -1 1 FLAT-RAISE))
                        (deh . ,(ly:make-pitch -1 1 QUARTER-FLAT))
                        (de . ,(ly:make-pitch -1 1 NATURAL-LOWER))
                        (d . ,(ly:make-pitch -1 1 NATURAL))
                        (di . ,(ly:make-pitch -1 1 NATURAL-RAISE))
                        (dih . ,(ly:make-pitch -1 1 QUARTER-SHARP))
                        (dise . ,(ly:make-pitch -1 1 SHARP-LOWER))
                        (dis . ,(ly:make-pitch -1 1 SHARP))
                        (disi . ,(ly:make-pitch -1 1 SHARP-RAISE))
                        (disih . ,(ly:make-pitch -1 1 THREE-QUARTER-SHARP))
                        (disis . ,(ly:make-pitch -1 1 DOUBLE-SHARP))

                        (eeses . ,(ly:make-pitch -1 2 DOUBLE-FLAT))
                        (eeseh . ,(ly:make-pitch -1 2 THREE-QUARTER-FLAT))
                        (eese . ,(ly:make-pitch -1 2 FLAT-LOWER))
                        (ees . ,(ly:make-pitch -1 2 FLAT))
                        (eesi . ,(ly:make-pitch -1 2 FLAT-RAISE))
                        (eeh . ,(ly:make-pitch -1 2 QUARTER-FLAT))
                        (ee . ,(ly:make-pitch -1 2 NATURAL-LOWER))
                        (e . ,(ly:make-pitch -1 2 NATURAL))
                        (ei . ,(ly:make-pitch -1 2 NATURAL-RAISE))
                        (eih . ,(ly:make-pitch -1 2 QUARTER-SHARP))
                        (eise . ,(ly:make-pitch -1 2 SHARP-LOWER))
                        (eis . ,(ly:make-pitch -1 2 SHARP))
                        (eisi . ,(ly:make-pitch -1 2 SHARP-RAISE))
                        (eisih . ,(ly:make-pitch -1 2 THREE-QUARTER-SHARP))
                        (eisis . ,(ly:make-pitch -1 2 DOUBLE-SHARP))

                        (feses . ,(ly:make-pitch -1 3 DOUBLE-FLAT))
                        (feseh . ,(ly:make-pitch -1 3 THREE-QUARTER-FLAT))
                        (fese . ,(ly:make-pitch -1 3 FLAT-LOWER))
                        (fes . ,(ly:make-pitch -1 3 FLAT))
                        (fesi . ,(ly:make-pitch -1 3 FLAT-RAISE))
                        (feh . ,(ly:make-pitch -1 3 QUARTER-FLAT))
                        (fe . ,(ly:make-pitch -1 3 NATURAL-LOWER))
                        (f . ,(ly:make-pitch -1 3 NATURAL))
                        (fi . ,(ly:make-pitch -1 3 NATURAL-RAISE))
                        (fih . ,(ly:make-pitch -1 3 QUARTER-SHARP))
                        (fise . ,(ly:make-pitch -1 3 SHARP-LOWER))
                        (fis . ,(ly:make-pitch -1 3 SHARP))
                        (fisi . ,(ly:make-pitch -1 3 SHARP-RAISE))
                        (fisih . ,(ly:make-pitch -1 3 THREE-QUARTER-SHARP))
                        (fisis . ,(ly:make-pitch -1 3 DOUBLE-SHARP))

                        (geses . ,(ly:make-pitch -1 4 DOUBLE-FLAT))
                        (geseh . ,(ly:make-pitch -1 4 THREE-QUARTER-FLAT))
                        (gese . ,(ly:make-pitch -1 4 FLAT-LOWER))
                        (ges . ,(ly:make-pitch -1 4 FLAT))
                        (gesi . ,(ly:make-pitch -1 4 FLAT-RAISE))
                        (geh . ,(ly:make-pitch -1 4 QUARTER-FLAT))
                        (ge . ,(ly:make-pitch -1 4 NATURAL-LOWER))
                        (g . ,(ly:make-pitch -1 4 NATURAL))
                        (gi . ,(ly:make-pitch -1 4 NATURAL-RAISE))
                        (gih . ,(ly:make-pitch -1 4 QUARTER-SHARP))
                        (gise . ,(ly:make-pitch -1 4 SHARP-LOWER))
                        (gis . ,(ly:make-pitch -1 4 SHARP))
                        (gisi . ,(ly:make-pitch -1 4 SHARP-RAISE))
                        (gisih . ,(ly:make-pitch -1 4 THREE-QUARTER-SHARP))
                        (gisis . ,(ly:make-pitch -1 4 DOUBLE-SHARP))

                        (aeses . ,(ly:make-pitch -1 5 DOUBLE-FLAT))
                        (aeseh . ,(ly:make-pitch -1 5 THREE-QUARTER-FLAT))
                        (aese . ,(ly:make-pitch -1 5 FLAT-LOWER))
                        (aes . ,(ly:make-pitch -1 5 FLAT))
                        (aesi . ,(ly:make-pitch -1 5 FLAT-RAISE))
                        (aeh . ,(ly:make-pitch -1 5 QUARTER-FLAT))
                        (ae . ,(ly:make-pitch -1 5 NATURAL-LOWER))
                        (a . ,(ly:make-pitch -1 5 NATURAL))
                        (ai . ,(ly:make-pitch -1 5 NATURAL-RAISE))
                        (aih . ,(ly:make-pitch -1 5 QUARTER-SHARP))
                        (aise . ,(ly:make-pitch -1 5 SHARP-LOWER))
                        (ais . ,(ly:make-pitch -1 5 SHARP))
                        (aisi . ,(ly:make-pitch -1 5 SHARP-RAISE))
                        (aisih . ,(ly:make-pitch -1 5 THREE-QUARTER-SHARP))
                        (aisis . ,(ly:make-pitch -1 5 DOUBLE-SHARP))

                        (beses . ,(ly:make-pitch -1 6 DOUBLE-FLAT))
                        (beseh . ,(ly:make-pitch -1 6 THREE-QUARTER-FLAT))
                        (bese . ,(ly:make-pitch -1 6 FLAT-LOWER))
                        (bes . ,(ly:make-pitch -1 6 FLAT))
                        (besi . ,(ly:make-pitch -1 6 FLAT-RAISE))
                        (beh . ,(ly:make-pitch -1 6 QUARTER-FLAT))
                        (be . ,(ly:make-pitch -1 6 NATURAL-LOWER))
                        (b . ,(ly:make-pitch -1 6 NATURAL))
                        (bi . ,(ly:make-pitch -1 6 NATURAL-RAISE))
                        (bih . ,(ly:make-pitch -1 6 QUARTER-SHARP))
                        (bise . ,(ly:make-pitch -1 6 SHARP-LOWER))
                        (bis . ,(ly:make-pitch -1 6 SHARP))
                        (bisi . ,(ly:make-pitch -1 6 SHARP-RAISE))
                        (bisih . ,(ly:make-pitch -1 6 THREE-QUARTER-SHARP))
                        (bisis . ,(ly:make-pitch -1 6 DOUBLE-SHARP))
                        )

pitchnames = \arrowedPitchNames
#(ly:parser-set-note-names parser pitchnames)

arrowGlyphs = #`(
                  (,DOUBLE-FLAT . "accidentals.flatflat")
                  (,THREE-QUARTER-FLAT . "accidentals.mirroredflat.flat")
                  (,FLAT-LOWER . "accidentals.flat.arrowdown")
                  (,FLAT . "accidentals.flat")
                  (,FLAT-RAISE . "accidentals.flat.arrowup")
                  (,QUARTER-FLAT . "accidentals.mirroredflat")
                  (,NATURAL-LOWER . "accidentals.natural.arrowdown")
                  ( 0 . "accidentals.natural")
                  (,NATURAL-RAISE . "accidentals.natural.arrowup")
                  (,QUARTER-SHARP . "accidentals.sharp.slashslash.stem")
                  (,SHARP-LOWER . "accidentals.sharp.arrowdown")
                  (,SHARP . "accidentals.sharp")
                  (,SHARP-RAISE . "accidentals.sharp.arrowup")
                  (,THREE-QUARTER-SHARP . "accidentals.sharp.slashslashslash.stemstem")
                  (,DOUBLE-SHARP . "accidentals.doublesharp")
                  )