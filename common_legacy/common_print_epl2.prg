/*
 * This file is part of the bring.out FMK, a free and open source
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */


#include "f18.ch"

// parametri
STATIC par_1
STATIC par_2
STATIC par_3
STATIC par_4

STATIC last_nX
STATIC last_nY
#define EPL2_DOT 7.8



// --------------------------------------------------
// print string
// nRotate - 0 - bez rotiranja, 3 - 270 stepeni
// nInvert - 0 - ne f18_color_invert() uj background, 1 - f18_color_invert()
// nFontSize - 1 - najmanji, 5 - najveci
// --------------------------------------------------
FUNCTION epl2_string( nX, nY, cString, lAbsolute, nFontSize, nRotate, nInvert )

   LOCAL cStr
   LOCAL cVelicina

   // povecanje u procentima  proreda
   LOCAL nRowDelta := 0

   IF nRotate == nil
      nRotate := 0
   ENDIF

   IF nInvert == nil
      nInvert := 0
   ENDIF

   IF lAbsolute == nil
      lAbsolute := .T.
   ENDIF

   IF nFontSize == nil
      nFontSize := 2
   ENDIF

   // F+1Ernad Husremovic idev fontom vecim za 1 u odnosu na tekuci
   IF Left( cString, 2 ) == "F+"
      cVelicina := SubStr( cString, 3, 1 )
      nFontSize += Val( cVelicina )
      // prored mora biti 30% veci
      nRowDelta := 30
      cString := SubStr( cString, 4 )
   ENDIF

   // F-1Ernad Husremovic idev fontom manjim za 1 u odnosu na tekuci
   IF Left( cString, 2 ) == "F-"
      cVelicina := SubStr( cString, 3, 1 )
      nFontSize -= Val( cVelicina )
      // prored mora biti 30% manji
      nRowDelta := -30
      cString := SubStr( cString, 4 )
   ENDIF

   IF !lAbsolute
      nX := last_nX + nX
      nY := Round( last_nY + nY * ( 100 + nRowDelta ) / 100, 0 )
   ELSE
      // ako je apsolutno zadano onda ne mogu napraviti povecanje
   ENDIF

   last_nX := nX
   last_nY := nY

   cStr := "A" + AllTrim( Str( nX, 0 ) ) + ","
   cStr += AllTrim( Str( nY, 0 ) ) + ","
   cStr += AllTrim( Str( nRotate, 0 ) ) + ","
   cStr += AllTrim( Str( nFontSize, 0 ) ) + ","
   // horizontal multiplexer
   cStr += AllTrim( Str( 1, 0 ) ) + ","
   // vertical multiplexer
   cStr += AllTrim( Str( 1, 0 ) ) + ","
   IF nInvert == 0
      cStr += "N"
   ELSE
      cStr += "R"
   ENDIF
   cStr += ","

   // " => \"
   cString := StrTran( cString, '"', '\"' )
   cStr += '"' + cString + '"'

   ? cStr

   // -----------------------------------
   // label width
   // -----------------------------------

FUNCTION epl2_f_width( nMM )

   ? 'q' + AllTrim( Str( mm2dot( nMM ), 0 ) )

   RETURN

// ---------------------------
// setuj gornju i lijevu marginu
// ---------------------------
FUNCTION epl2_f_init( nX, nY )

   last_nX := nX
   last_nY := nY

   RETURN


// -----------------------------------
// start novu formu
// -----------------------------------
FUNCTION epl2_f_start( nKolicina )

   ? 'N'

   RETURN

// -----------------------------------
// print formu
// -----------------------------------
FUNCTION epl2_f_print( nKolicina )

   IF nKolicina == nil
      nKolicina := 1
   ENDIF
   ? 'P' + AllTrim( Str( Round( nKolicina, 0 ), 0 ) )

   RETURN


// --------------------------------
// --------------------------------
FUNCTION dot2mm( nDots )
   RETURN Round( nDots / EPL2_DOT, 0 )

// --------------------------------
// --------------------------------
FUNCTION mm2dot( nMM )
   RETURN Round( nMM * EPL2_DOT, 0 )


// --------------------------------
// --------------------------------
FUNCTION epl2_cp852()

   ? 'I8,2,049'

   RETURN .T.

// --------------------------
// start print na EPL2
// --------------------------
FUNCTION epl2_start()

   last_nX := 0
   last_nY := 0

   par_1 := gPrinter
   par_2 := gcDirekt
   par_3 := gPTKonv
   par_4 := gKodnaS

   // uzmi parametre iz printera "L"
   SELECT F_GPARAMS
   IF !Used()
      o_gparams()
   ENDIF

   // gcDirekt := "D"
   gPrinter := "L"
   gPTKonv := "0 "
   gKodnaS := "8"

   PRIVATE cSection := "P"
   PRIVATE cHistory := gPrinter
   PRIVATE aHistory := {}

   RPar_Printer()

   START PRINT CRET

   RETURN .T.



// -------------------------------
// vrati standardne printer parametre
// -------------------------------
FUNCTION epl2_end()

   ?
   // zavrsi stampu
   ENDPRINT

   // vrati tekuce parametre
   gPrinter := par_1
   gcDirekt := par_2
   gPTKonv := par_3
   gKodnaS := par_4

   SELECT F_GPARAMS
   IF !Used()
      o_gparams()
   ENDIF

   PRIVATE cSection := "P"
   PRIVATE cHistory := gPrinter
   PRIVATE aHistory := {}

   RPar_Printer()

   SELECT gparams
   USE

   RETURN .T.
