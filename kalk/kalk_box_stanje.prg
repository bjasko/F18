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



FUNCTION KalkStanje( cIdRoba )

   LOCAL nUl, nIzl, nRezerv, nRevers, fOtv := .F., nIOrd, nFRec, aStanje
   LOCAL aZN := { CToD( "" ), 0, 0, 0 } // zadnja nabavka

   PushWA()

   //SELECT roba

/*
   SELECT ( F_KALK )
   IF !Used()
    --  o_kalk()
      fOtv := .T.
   ELSE
      nIOrd := IndexOrd()
      nFRec := RecNo()
   ENDIF


   SET ORDER TO TAG "7" // "7","Idroba"
   SEEK cIdRoba
*/

   find_kalk_za_period( self_organizacija_id(), NIL, NIL, cIdRoba )


   aStanje := {}

   // {idkonto, nUl,nIzl }         KALK

   nUl := nIzl := 0

   DO WHILE !Eof()  .AND. cIdRoba == IdRoba
      nUlaz := nIzlaz := 0
      IF !Empty( mkonto )
         nPos := AScan ( aStanje, {| x| x[ 1 ] == KALK->mkonto } )
         IF nPos == 0
            AAdd ( aStanje, { mkonto, 0, 0 } )
            nPos := Len ( aStanje )
         ENDIF
         IF mu_i == "1" .AND. !( idvd $ "12#22#94" )
            nUlaz  := kolicina - gkolicina - gkolicin2
         ELSEIF mu_i == "5"
            nIzlaz := kolicina
         ELSEIF mu_i == "1" .AND. ( idvd $ "12#22#94" )    // povrat
            nIzlaz := -kolicina
         ELSEIF mu_i == "8"
            nIzlaz := -kolicina
            nUlaz  := -kolicina
         ENDIF
      ELSE
         nPos := AScan ( aStanje, {| x| x[ 1 ] == KALK->pkonto } )
         IF nPos == 0
            AAdd ( aStanje, { pkonto, 0, 0 } )
            nPos := Len ( aStanje )
         ENDIF
         IF pu_i == "1"
            nUlaz  := kolicina - GKolicina - GKolicin2
         ELSEIF pu_i == "5"  .AND. !( idvd $ "12#13#22" )
            nIzlaz := kolicina
         ELSEIF pu_i == "I"
            nIzlaz := gkolicin2
         ELSEIF pu_i == "5"  .AND. ( idvd $ "12#13#22" )    // povrat
            nUlaz  := -kolicina
         ENDIF
      ENDIF
      aStanje[ nPos, 2 ] += nUlaz
      aStanje[ nPos, 3 ] += nIzlaz
      IF idvd == "10" .AND. kolicina > 0 .AND. datdok >= aZN[ 1 ]
         aZN[ 1 ] := datdok
         aZN[ 2 ] := fcj
         aZN[ 3 ] := rabat
         aZN[ 4 ] := nc
      ENDIF
      SKIP 1
   ENDDO

   PRIVATE ZN_Datum  := aZN[ 1 ]           // datum zadnje nabavke
   PRIVATE ZN_FakCij := aZN[ 2 ]           // fakturna cijena po zadnjoj nabavci
   PRIVATE ZN_Rabat  := aZN[ 3 ]           // rabat po zadnjoj nabavci
   PRIVATE ZN_NabCij := aZN[ 4 ]           // nabavna cijena po zadnjoj nabavci

   //SELECT roba

   BoxStanje( aStanje, cIdRoba )      // nUl,nIzl

   PopWa()

   RETURN .T.




/* BoxStanje(aStanje,cIdRoba)
 *     Prikaz stanja robe
 */

FUNCTION BoxStanje( aStanje, cIdroba )

   LOCAL picdem := "9999999.999", nR, nC, nTSta := 0, nTUl := 0, nTIzl := 0, ;
      npd, cDiv := "sum", nLen, nRPoc := 0

   npd := Len ( picdem )
   nLen := Len ( aStanje )
   nLenKonta := IF( nLen > 0, Len( aStanje[ 1, 1 ] ), 7 )

   ASort( aStanje,,, {| x, y| x[ 1 ] < y[ 1 ] } )

   // ucitajmo dodatne parametre stanja iz FMK.INI u aDodPar
   // ------------------------------------------------------
   aDodPar := {}
   FOR i := 1 TO 6
      cI := AllTrim( Str( i ) )
      cPomZ := my_get_from_ini( "BoxStanje", "ZaglavljeStanje" + cI, "", KUMPATH )
      cPomF := my_get_from_ini( "BoxStanje", "FormulaStanje" + cI, "", KUMPATH )
      IF !Empty( cPomF )
         AAdd( aDodPar, { cPomZ, cPomF } )
      ENDIF
   NEXT
   nLenDP := IF( Len( aDodPar ) > 0, Len( aDodPar ) + 1, 0 )

   SELECT roba
   // PushWA()
   SET ORDER TO TAG "ID"
   SEEK cIdRoba
   Box( , Min( 6 + nLen + Int( ( nLenDP ) / 2 ), 23 ), 75 )
   Beep( 1 )
   @ form_x_koord() + 1, form_y_koord() + 2 SAY "ARTIKAL: "
   @ form_x_koord() + 1, Col() SAY PadR( AllTrim ( cIdRoba ) + " - " + roba->naz, 51 ) COLOR "GR+/B"
   @ form_x_koord() + 3, form_y_koord() + 2 SAY cDiv + PadC( "KONTO", nLenKonta ) + cDiv + PadC ( "Ulaz", npd ) + cDiv + ;
      PadC ( "Izlaz", npd ) + cDiv + ;
      PadC ( "Stanje", npd ) + cDiv
   nR := form_x_koord() + 4
   nRPoc := nR
   FOR nC := 1 TO nLen
      // {idfirma, nUl,nIzl,nRevers,nRezerv }
      @ nR, form_y_koord() + 2 SAY cDiv
      @ nR, Col() SAY aStanje[ nC ][ 1 ]
      @ nR, Col() SAY cDiv
      @ nR, Col() SAY aStanje[ nC ][ 2 ] PICT picdem
      @ nR, Col() SAY cDiv
      @ nR, Col() SAY aStanje[ nC ][ 3 ] PICT picdem
      @ nR, Col() SAY cDiv
      nPom := aStanje[ nC ][ 2 ] -aStanje[ nC ][ 3 ]
      @ nR, Col() SAY nPom PICT picdem
      @ nR, Col() SAY cDiv
      nTUl  += aStanje[ nC ][ 2 ]
      nTIzl += aStanje[ nC ][ 3 ]
      nTSta += nPom
      nR ++

      IF nC % 15 = 0 .AND. nC < nLen
         Inkey( 0 )
         @ form_x_koord() + nRPoc, form_y_koord() + 2 CLEAR TO form_x_koord() + nR - 1, form_y_koord() + 70
         nR := nRPoc
      ENDIF

   NEXT
   @ nR, form_y_koord() + 2 SAY cDiv + REPL( "-", nLenKonta ) + cDiv + REPL ( "-", npd ) + cDiv + ;
      REPL ( "-", npd ) + cDiv + ;
      REPL ( "-", npd ) + cDiv
   nR ++
   @ nR, form_y_koord() + 2 SAY cDiv + PadC( "UKUPNO:", nLenKonta ) + cDiv
   @ nR, Col() SAY nTUl PICT picdem
   @ nR, Col() SAY cDiv
   @ nR, Col() SAY nTIzl PICT picdem
   @ nR, Col() SAY cDiv
   @ nR, Col() SAY nTSta PICT picdem
   @ nR, Col() SAY cDiv

   // ispis dodatnih parametara stanja
   // --------------------------------
   IF nLenDP > 0
      ++nR
      @ nR, form_y_koord() + 2 SAY REPL( "-", 74 )
      FOR i := 1 TO nLenDP - 1

         cPom777 := aDodPar[ i, 2 ]

         IF "TARIFA->" $ Upper( cPom777 )
            select_o_tarifa( ROBA->idtarifa )
            SELECT ROBA
         ENDIF

         IF i % 2 != 0
            ++nR
            @ nR, form_y_koord() + 2 SAY PadL( aDodPar[ i, 1 ], 15 ) COLOR "W+/B"
            @ nR, Col() + 2 SAY &cPom777 COLOR "R/W"
         ELSE
            @ nR, form_y_koord() + 37 SAY PadL( aDodPar[ i, 1 ], 15 ) COLOR "W+/B"
            @ nR, Col() + 2 SAY &cPom777 COLOR "R/W"
         ENDIF

      NEXT
   ENDIF

   Inkey( 0 )
   BoxC()
   // PopWa()

   RETURN
// }
