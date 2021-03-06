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

// --------------------------------
// pretvara mm u inch-e
// --------------------------------
FUNCTION to_inch( nVal )

   LOCAL nConv := nVal

   IF nVal <> 0
      nConv := ROUND2( ( nVal / 25.4 ), 2 )
   ENDIF

   RETURN nConv


// -----------------------------------------------------
// kalkulise kvadratne metre
// nDim1, nDim2 u mm
// -----------------------------------------------------
FUNCTION c_ukvadrat( nKol, nDim1, nDim2 )

   LOCAL xRet

   xRet := ( nDim1 / 1000 ) * ( nDim2 / 1000 )
   xRet := nKol * xRet

   RETURN xRet



// -----------------------------------------------------
// kalkulise duzinske metre
// nDim1, nDim2 u mm
// -----------------------------------------------------
FUNCTION c_duzinski( nKol, nDim1, nDim2, nDim3, nDim4 )

   LOCAL xRet

   IF nDim3 == NIL .AND. nDim4 == nil
      xRet := ( ( ( nDim1 / 1000 )  * 2 ) + ( ( nDim2 / 1000 ) * 2 ) )
   ELSE
      xRet := ( ( nDim1 / 1000 ) + ( nDim2 / 1000 ) + ;
         ( nDim3 / 1000 ) + ( nDim4 / 1000 ) )
   ENDIF

   xRet := nKol * xRet

   RETURN xRet


// ------------------------------------------
// pretvara iznos u cent. u milimetr.
// ------------------------------------------
FUNCTION cm_2_mm( nVal )
   RETURN nVal * 10


// ------------------------------------------
// pretvara iznos iz mm u cm
// ------------------------------------------
FUNCTION mm_2_cm( nVal )
   RETURN nVal / 10


// ------------------------------------------
// pretvara mm u metre
// ------------------------------------------
FUNCTION mm_2_m( nVal )
   RETURN nVal / 1000


// ------------------------------------------
// pretvara m u mm
// ------------------------------------------
FUNCTION m_2_mm( nVal )
   RETURN nVal * 1000


// --------------------------------------------
// uklanjanje jokera iz stringa
// --------------------------------------------
FUNCTION rem_jokers( cVal )

   cVal := StrTran( cVal, "#G_CONFIG#", "" )
   cVal := StrTran( cVal, "#HOLE_CONFIG#", "" )
   cVal := StrTran( cVal, "#STAMP_CONFIG#", "" )
   cVal := StrTran( cVal, "#PREP_CONFIG#", "" )
   cVal := StrTran( cVal, "#RAL_CONFIG#", "" )

   RETURN



// ---------------------------------------------------
// ispisuje box sa slikom stakla i odabirom
// obrade na stranicama
// ---------------------------------------------------
FUNCTION rnal_konfigurator_stakla( nWidth, nHeigh, ;
      cV1, cV2, cV3, cV4, ;
      nR1, nR2, nR3, nR4 )

   LOCAL nBoxX := 17
   LOCAL nBoxY := 56

   LOCAL nGLen := 40
   LOCAL nGLeft := 8
   LOCAL nGTop := 4
   LOCAL nGBott := 15
   LOCAL cColSch := "GR+/G+"

   PRIVATE GetList := {}

   cV1 := "N"
   cV2 := cV1
   cV3 := cV1
   cV4 := cV1

   cD1 := "N"
   cD2 := cD1
   cD3 := cD1
   cD4 := cD1

   nR1 := 0
   nR2 := nR1
   nR3 := nR1
   nR4 := nR1

   Box(, nBoxX, nBoxY )

   nStX := box_x_koord() + 2
   nStY := box_y_koord() + 2

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "##glass_config##  select operations..."

   box_staklo( nGLen, nGTop, nGBott, nGLeft, cColSch, nWidth, nHeigh )

   // top
   @ box_x_koord() + nGTop - 1, box_y_koord() + ( nBoxY / 2 ) - 1 SAY "d1 ?" GET cV1 ;
      PICT "@!" VALID cV1 $ "DN"

   // left
   @ box_x_koord() + ( nBoxX / 2 ) + 1, box_y_koord() + ( nGLeft - 6 ) SAY "d2 ?" GET cV2 ;
      PICT "@!" VALID cV2 $ "DN"

   // right
   @ box_x_koord() + ( nBoxX / 2 ) + 1, box_y_koord() + ( nGLeft + nGLen + 3 ) SAY "d3 ?" GET cV3;
      PICT "@!" VALID cV3 $ "DN"

   // bottom
   @ box_x_koord() + nGBott + 1, box_y_koord() + ( nBoxY / 2 ) - 1 SAY "d4 ?" GET cV4 ;
      PICT "@!" VALID cV4 $ "DN"


   READ


   IF Pitanje(, "Definisati radijuse (D/N) ?", "N" ) == "D"

      @ nStX, nStY CLEAR TO nStX + nBoxX - 3, nStY + nBoxY - 2

      box_staklo( nGLen, nGTop, nGBott, nGLeft, cColSch, nWidth, nHeigh )

      // top left
      @ box_x_koord() + nGTop - 1, box_y_koord() + ( nGLeft - 4 ) SAY "r1 ?" GET cD1 ;
         PICT "@!" VALID cD1 $ "DN"

      @ box_x_koord() + nGTop - 1, Col() + 1 GET nR1 PICT "99999" ;
         WHEN cD1 == "D" VALID val_radius( nR1, nWidth, nHeigh )

      // top right
      @ box_x_koord() + nGTop - 1, box_y_koord() + ( nGLen + 3 ) SAY "r2 ?" GET cD2 ;
         PICT "@!" VALID cD2 $ "DN"

      @ box_x_koord() + nGTop - 1, Col() + 1 GET nR2 PICT "99999" ;
         WHEN cD2 == "D" VALID val_radius( nR2, nWidth, nHeigh )

      // bott. left
      @ box_x_koord() + nGBott + 1, box_y_koord() + ( nGLeft - 4 ) SAY "r3 ?" GET cD3;
         PICT "@!" VALID cD3 $ "DN"

      @ box_x_koord() + nGBott + 1, Col() + 1 GET nR3 PICT "99999" ;
         WHEN cD3 == "D" VALID val_radius( nR3, nWidth, nHeigh )

      // bott. right
      @ box_x_koord() + nGBott + 1, box_y_koord() + ( nGLen + 3 ) SAY "r4 ?" GET cD4 ;
         PICT "@!" VALID cD4 $ "DN"

      @ box_x_koord() + nGBott + 1, Col() + 1 GET nR4 PICT "99999" ;
         WHEN cD4 == "D" VALID val_radius( nR4, nWidth, nHeigh )

      READ

   ENDIF

   BoxC()

   IF LastKey() == K_ESC
      RETURN .F.
   ENDIF

   RETURN .T.



FUNCTION rnal_konfiguracija_prepusta( cJoker, nWidth, nHeigh, ;
      nD1, nD2, nD3, nD4 )

   LOCAL nBoxX := 17
   LOCAL nBoxY := 66

   LOCAL nGLen := 38
   LOCAL nGLeft := 13
   LOCAL nGTop := 4
   LOCAL nGBott := 15
   LOCAL cColSch := "GR+/G+"

   PRIVATE GetList := {}

   nD1 := nWidth
   nD2 := nHeigh
   nD3 := nD2
   nD4 := nD1

   Box(, nBoxX, nBoxY )

   nStX := box_x_koord() + 2
   nStY := box_y_koord() + 2

   @ box_x_koord() + 1, box_y_koord() + 2 SAY "##glass_config## konfigurisanje prepusta..."

   box_staklo( nGLen, nGTop, nGBott, nGLeft, cColSch, nWidth, nHeigh )

   // top
   @ box_x_koord() + nGTop - 1, box_y_koord() + ( nBoxY / 2 ) - 1 SAY "A:" GET nD1 ;
      PICT pic_dim()

   // left
   @ box_x_koord() + ( nBoxX / 2 ) + 1, box_y_koord() + ( nGLeft - 10 ) SAY "B:" GET nD2 ;
      PICT pic_dim()

   // right
   @ box_x_koord() + ( nBoxX / 2 ) + 1, box_y_koord() + ( nGLeft + nGLen + 3 ) SAY "C:" GET nD3;
      PICT pic_dim()

   // bottom
   @ box_x_koord() + nGBott + 1, box_y_koord() + ( nBoxY / 2 ) - 1 SAY "D:" GET nD4 ;
      PICT pic_dim()

   READ

   BoxC()

   IF LastKey() == K_ESC
      RETURN ""
   ENDIF

   IF ( nD1 = nWidth .AND. nD4 = nWidth ) .AND. ;
         ( nD2 = nHeigh .AND. nD3 = nHeigh )
      RETURN ""
   ENDIF

   cTmp := ""

   IF nD1 > 0
      cTmp += "A=" + AllTrim( Str( nD1, 12, 2 ) ) + "#"
   ENDIF
   IF nD2 > 0
      cTmp += "B=" + AllTrim( Str( nD2, 12, 2 ) ) + "#"
   ENDIF
   IF nD3 > 0
      cTmp += "C=" + AllTrim( Str( nD3, 12, 2 ) ) + "#"
   ENDIF
   IF nD4 > 0
      cTmp += "D=" + AllTrim( Str( nD4, 12, 2 ) ) + "#"
   ENDIF

   IF !Empty( cTmp )
      cTmp := "#" + cTmp
   ENDIF

   // <A_PREP>:#D1=2#D2=5#

   IF !Empty( cTmp )
      cRet := cJoker + ":" + cTmp
   ENDIF

   RETURN cRet


FUNCTION rnal_konfiguracija_dimenzija_rupa( cJoker )

   LOCAL nBoxX := 12
   LOCAL nBoxY := 65
   LOCAL nX := 1
   LOCAL cRet := ""
   LOCAL nHole1 := 0
   LOCAL nHole2 := 0
   LOCAL nHole3 := 0
   LOCAL nHole4 := 0
   LOCAL nHole5 := 0
   LOCAL nHole6 := 0
   LOCAL nHole7 := 0
   LOCAL nHole8 := 0
   LOCAL nHole9 := 0
   LOCAL nHole10 := 0
   LOCAL cTmp := ""
   LOCAL GetList := {}

   Box(, nBoxX, nBoxY )

   @ box_x_koord() + nX, box_y_koord() + 2 SAY "#HOLE_CONFIG#"

   nX += 2
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 1 (fi):" GET nHole1 PICT "999"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 2 (fi):" GET nHole2 PICT "999"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 3 (fi):" GET nHole3 PICT "999"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 4 (fi):" GET nHole4 PICT "999"

   nX += 1
   @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 5 (fi):" GET nHole5 PICT "999"

   READ

   IF Pitanje(, "Da li postoje dodatne rupe (D/N) ?", "N" ) == "D"

      nX += 1
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 6 (fi):" GET nHole6 PICT "999"

      nX += 1
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 7 (fi):" GET nHole7 PICT "999"

      nX += 1
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 8 (fi):" GET nHole8 PICT "999"

      nX += 1
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 9 (fi):" GET nHole9 PICT "999"

      nX += 1
      @ box_x_koord() + nX, box_y_koord() + 2 SAY "Rupa 10 (fi):" GET nHole10 PICT "999"

      READ

   ENDIF
   BoxC()

   cTmp := ""

   IF nHole1 <> 0
      cTmp += "H1=" + AllTrim( Str( nHole1 ) ) + "#"
   ENDIF

   IF nHole2 <> 0
      cTmp += "H2=" + AllTrim( Str( nHole2 ) ) + "#"
   ENDIF

   IF nHole3 <> 0
      cTmp += "H3=" + AllTrim( Str( nHole3 ) ) + "#"
   ENDIF

   IF nHole4 <> 0
      cTmp += "H4=" + AllTrim( Str( nHole4 ) ) + "#"
   ENDIF

   IF nHole5 <> 0
      cTmp += "H5=" + AllTrim( Str( nHole5 ) ) + "#"
   ENDIF

   IF nHole6 <> 0
      cTmp += "H6=" + AllTrim( Str( nHole6 ) ) + "#"
   ENDIF

   IF nHole7 <> 0
      cTmp += "H7=" + AllTrim( Str( nHole7 ) ) + "#"
   ENDIF

   IF nHole8 <> 0
      cTmp += "H8=" + AllTrim( Str( nHole8 ) ) + "#"
   ENDIF

   IF nHole9 <> 0
      cTmp += "H9=" + AllTrim( Str( nHole9 ) ) + "#"
   ENDIF

   IF nHole10 <> 0
      cTmp += "H10=" + AllTrim( Str( nHole10 ) ) + "#"
   ENDIF

   IF !Empty( cTmp )
      cTmp := "#" + cTmp
   ENDIF

   // <A_BU_HOLE>:#H1=2#H2=5#

   IF !Empty( cTmp )
      cRet := cJoker + ":" + cTmp
   ENDIF

   RETURN cRet



FUNCTION rnal_dimenzije_rupa_za_nalog( cValue )

   LOCAL cRet := ""
   LOCAL aTmp
   LOCAL cTmp
   LOCAL aTmp2
   LOCAL i
   LOCAL aHole

   // "<A_BU>:#H1=24#H2=55#"
   aTmp := TokToNiz( cValue, ":" )

   IF aTmp[ 1 ] <> "<A_BU>"
      RETURN cRet
   ENDIF

   cTmp := AllTrim( aTmp[ 2 ] )

   aTmp2 := TokToNiz( cTmp, "#" )

   // H1=24, H2=55

   FOR i := 1 TO Len( aTmp2 )

      aHole := {}
      aHole := TokToNiz( aTmp2[ i ], "=" )

      cHoleTick := AllTrim( aHole[ 2 ] )

      cRet += "fi=" + cHoleTick + " mm, "
   NEXT

   RETURN cRet



FUNCTION rnal_dimenzije_prepusta_za_nalog( cValue, nW, nH )

   LOCAL cRet := ""
   LOCAL aTmp
   LOCAL cTmp
   LOCAL aTmp2
   LOCAL i
   LOCAL aPrep

   // "<A_PREP>:#A=24#B=55#"
   aTmp := TokToNiz( cValue, ":" )

   IF aTmp[ 1 ] <> "<A_PREP>"
      RETURN cRet
   ENDIF

   cTmp := AllTrim( aTmp[ 2 ] )

   aTmp2 := TokToNiz( cTmp, "#" )

   // i sada imamo dimenzije ...
   // A=24, B=55, C=...

   FOR i := 1 TO Len( aTmp2 )

      aPrep := {}
      aPrep := TokToNiz( aTmp2[ i ], "=" )

      cPrepPos := AllTrim( aPrep[ 1 ] )
      cPrepDim := AllTrim( aPrep[ 2 ] )

      IF cPrepPos == "A"
         nW := Val( cPrepDim )
      ENDIF

      IF cPrepPos == "B"
         nH := Val( cPrepDim )
      ENDIF

      cRet += aTmp2[ i ] + " mm, "
   NEXT

   RETURN cRet



FUNCTION izracunaj_dimenzije_prepusta( cVal, nW, nH )
   RETURN rnal_dimenzije_prepusta_za_nalog( cVal, @nW, @nH )




FUNCTION rnal_konfigurator_pozicije_pecata( cJoker, nWidth, nHeigh )

   LOCAL nBoxX := 17
   LOCAL nBoxY := 56
   LOCAL cReturn := ""
   LOCAL cTmp := ""
   LOCAL nGLen := 40
   LOCAL nGLeft := 2
   LOCAL nGTop := 6
   LOCAL nGBott := 15
   LOCAL cColSch := "GR+/G+"
   LOCAL cColRed := "GR+/R+"

   PRIVATE GetList := {}

   cStampInfo := "P"
   cStampSch := "N"
   nX1 := nY1 := 0
   nX2 := nY2 := 0
   nX3 := nY3 := 0
   nX4 := nY4 := 0

   Box(, nBoxX, nBoxY )

   DO WHILE .T.

      nStX := box_x_koord() + 2
      nStY := box_y_koord() + 2

      @ box_x_koord() + 1, box_y_koord() + 2 SAY8 "### Odabir pozicije pečata na staklu"

      @ box_x_koord() + 2, box_y_koord() + 2 SAY8 "vrsta pečata [P]ositiv / [N]egativ:" GET cStampInfo VALID cStampInfo $ "PN" PICT "@!"

      @ box_x_koord() + 3, box_y_koord() + 2 SAY8 "pogledati šemu u prilogu (D/N)?" GET cStampSch VALID cStampSch $ "DN" PICT "@!"

      READ

      IF cStampSch == "N"

         box_staklo( nGLen, nGTop, nGBott, nGLeft + 6, cColSch, nWidth, nHeigh )

         @ box_x_koord() + nGTop - 1, box_y_koord() + ( nGlen / 2 ) + 4 SAY "X dim." COLOR cColRed
         @ box_x_koord() + nGTop + 4, box_y_koord() + nGLeft SAY "Y dim." COLOR cColRed

         @ box_x_koord() + nGTop - 1, box_y_koord() + nGLeft SAY "X" GET nX1 PICT "999"
         @ box_x_koord() + nGTop - 1, Col() + 1 SAY "/Y" GET nY1 PICT "999" VALID val_pecat( nX1, nY1 )
         @ box_x_koord() + nGTop - 1, Col() SAY "mm"

         @ box_x_koord() + nGTop - 1, Col() + nGLen - 15 SAY "X" GET nX2 PICT "999"
         @ box_x_koord() + nGTop - 1, Col() + 1 SAY "/Y" GET nY2 PICT "999" VALID val_pecat( nX2, nY2 )
         @ box_x_koord() + nGTop - 1, Col() SAY "mm"

         @ box_x_koord() + nGBott + 1, box_y_koord() + nGLeft SAY "X" GET nX3 PICT "999"
         @ box_x_koord() + nGBott + 1, Col() + 1 SAY "/Y" GET nY3 PICT "999" VALID val_pecat( nX3, nY3 )
         @ box_x_koord() + nGBott + 1, Col() SAY "mm"

         @ box_x_koord() + nGBott + 1, Col() + ( nGLen - 15 ) SAY "X"GET nX4 PICT "999"
         @ box_x_koord() + nGBott + 1, Col() + 1 SAY "/Y" GET nY4 PICT "999" VALID val_pecat( nX4, nY4 )
         @ box_x_koord() + nGBott + 1, Col() SAY "mm"

         READ

         IF LastKey() == K_ESC
            EXIT
         ENDIF

         IF ( nX1 + nX2 + nX3 + nX4 + nY1 + nY2 + nY3 + nY4 ) <> 0
            EXIT
         ENDIF

      ELSE
         EXIT
      ENDIF

   ENDDO

   BoxC()

   IF LastKey() == K_ESC
      RETURN cReturn
   ENDIF

   cTmp := ""

   IF nX1 <> 0
      cTmp += "X1=" + AllTrim( Str( nX1 ) ) + "#"
   ENDIF
   IF nY1 <> 0
      cTmp += "Y1=" + AllTrim( Str( nY1 ) ) + "#"
   ENDIF
   IF nX2 <> 0
      cTmp += "X2=" + AllTrim( Str( nX2 ) ) + "#"
   ENDIF
   IF nY2 <> 0
      cTmp += "Y2=" + AllTrim( Str( nY2 ) ) + "#"
   ENDIF
   IF nX3 <> 0
      cTmp += "X3=" + AllTrim( Str( nX3 ) ) + "#"
   ENDIF
   IF nY3 <> 0
      cTmp += "Y3=" + AllTrim( Str( nY3 ) ) + "#"
   ENDIF
   IF nX4 <> 0
      cTmp += "X4=" + AllTrim( Str( nX4 ) ) + "#"
   ENDIF
   IF nY4 <> 0
      cTmp += "Y4=" + AllTrim( Str( nY4 ) ) + "#"
   ENDIF

   IF !Empty( cTmp ) .OR. cStampSch == "D"

      IF cStampSch == "D"
         cTmp := cStampSch
      ENDIF

      cReturn := "STAMP" + ":" + cStampInfo + "#" + cTmp

   ENDIF

   RETURN cReturn



FUNCTION rnal_pozicija_pecata_stavke( cStampStr )

   LOCAL cRet := ""
   LOCAL i
   LOCAL aTmp
   LOCAL aTmp2
   LOCAL aTmp3

   IF Empty( cStampStr )
      RETURN cRet
   ENDIF

   // ex: "<A_K>:P#X1=20#Y1=25" => {<A_K>} {P#X1=20#Y1=25}
   aTmp := TokToNiz( cStampStr, ":" )

   IF aTmp[ 1 ] <> "STAMP"
      RETURN cRet
   ENDIF

   // ex: "P#X1=20#Y1=25" =>  {P} {X1=20} {Y1=25}
   aTmp2 := TokToNiz( aTmp[ 2 ], "#" )

   cRet := "pozicija pecata: "

   IF aTmp2[ 1 ] == "P"
      cRet += "pozitiv, "
   ELSEIF aTmp2[ 1 ] == "N"
      cRet += "negativ, "
   ENDIF

   IF aTmp2[ 2 ] == "D"
      // ex: "P#D" => {P} {D}
      cRet += " (pogledaj shemu u prilogu) "
      RETURN cRet
   ENDIF

   IF LEN( aTmp2 ) >= 2
      aTmp3 := TokToNiz( aTmp2[ 2 ], "=" )

      cRet += pozicija_pecata_opis( aTmp3[ 1 ] )
      cRet += " "
      cRet += AllTrim( aTmp3[ 2 ] )
      cRet += " mm - "
   ELSE
      cRet += "nedefinisana X pozicija "
   ENDIF

   IF LEN( aTmp2 ) >= 3
      aTmp3 := TokToNiz( aTmp2[ 3 ], "=" )

      cRet += pozicija_pecata_opis( aTmp3[ 1 ] )
      cRet += " "
      cRet += AllTrim( aTmp3[ 2 ] )
      cRet += " mm"
   ELSE
      cRet += "nedefinisana Y pozicija "
   ENDIF

   RETURN cRet


STATIC FUNCTION pozicija_pecata_opis( cVar )

   LOCAL cRet := ""

   DO CASE
   CASE cVar $ "X1#X2"
      cRet := "gore"
   CASE cVar $ "X3#X4"
      cRet := "dole"
   CASE cVar $ "Y1#Y3"
      cRet := "lijevo"
   CASE cVar $ "Y2#Y4"
      cRet := "desno"
   ENDCASE

   RETURN cRet



FUNCTION val_pecat( nX, nY )

   LOCAL lRet := .T.

   IF ( ( nX + nY ) > 0 ) .AND. ( nX == 0 .OR. nY == 0 )
      MsgBeep( "X i Y pozicije ne mogu biti 0 !" )
      lRet := .F.
   ENDIF

   RETURN lRet




// -------------------------
// validacija radijusa na
// osnovu dimenzija A i B
// stakla
// -------------------------
FUNCTION val_radius( nRadius, nA, nB )

   LOCAL lRet := .T.

   IF nRadius > ( nA / 2 ) .OR. nRadius > ( nB / 2 )
      lRet := .F.
   ENDIF

   IF lRet == .F.
      MsgBeep( "Radijus ne moze biti veci od pola duzine stranice !" )
   ENDIF

   RETURN lRet


// ----------------------------------------
// prikazuje sliku stakla unutar box-a
// nLenght - duzina stakla
// nTop - vrh stakla
// nBottom - dno stakla
// nLeft - lijeva strana
// cColSch - kolor shema
// ----------------------------------------
STATIC FUNCTION box_staklo( nLenght, nTop, nBottom, nLeft, cColSch, ;
      nWidth, nHeigh )

   LOCAL i
   LOCAL nTmp
   LOCAL nDimPos := nBottom - nTop

   // gornja strana
   @ box_x_koord() + nTop, box_y_koord() + nLeft SAY Chr( 218 ) ;
      COLOR cColSch
   @ box_x_koord() + nTop, box_y_koord() + nLeft + 1 SAY Replicate( Chr( 196 ), nLenght ) ;
      COLOR cColSch
   @ box_x_koord() + nTop, box_y_koord() + ( nLeft + 1 + nLenght ) SAY Chr( 191 ) ;
      COLOR cColSch

   nTmp := nTop + 1

   // popuna
   FOR i := nTmp TO nBottom
      @ box_x_koord() + i, box_y_koord() + nLeft SAY Chr( 179 ) + ;
         Replicate( Chr( 176 ), nLenght ) + Chr( 179 ) COLOR cColSch
   NEXT

   // donja strana
   @ box_x_koord() + nBottom, box_y_koord() + nLeft SAY Chr( 192 ) ;
      COLOR cColSch
   @ box_x_koord() + nBottom, box_y_koord() + nLeft + 1 SAY Replicate( Chr( 196 ), nLenght ) ;
      COLOR cColSch
   @ box_x_koord() + nBottom, box_y_koord() + nLeft + 1 + nLenght SAY Chr( 217 ) ;
      COLOR cColSch

   // ispisi dimenzije stakla
   @ box_x_koord() + nDimPos - 1, box_y_koord() + 20 SAY "glass dimensions:"
   @ box_x_koord() + nDimPos, box_y_koord() + 20 SAY AllTrim( Str( nWidth, 12, 2 ) ) + ;
      " x " + ;
      AllTrim( Str( nHeigh, 12, 2 ) ) + " mm"

   RETURN


// ---------------------------------
// glass tickness
// ---------------------------------
FUNCTION glass_tick( cTick )

   LOCAL nGlTick := 0
   LOCAL aTmp := {}
   LOCAL cTmp := ""
   LOCAL i

   // ovo je slucaj za LAMI staklo...
   IF "." $ cTick

      // ex: "33.1"
      aTmp := TokToNiz( cTick, "." )
      // ex: "33"
      cTmp := aTmp[ 1 ]

      FOR i := 1 TO Len( cTmp )
         nGlTick += Val ( SubStr( cTmp, i, 1 ) )
      NEXT

      // ex: "33" -> 6
   ELSE
      // klasicno staklo...
      nGlTick := Val( AllTrim( cTick ) )
   ENDIF

   RETURN nGlTick



// ---------------------------------------------
// da li se radi o rama-term staklu
// ---------------------------------------------
FUNCTION is_ramaterm( cArticle )

   LOCAL lRet := .F.

   IF "_A" $ cArticle
      lRet := .T.
   ENDIF

   RETURN lRet
