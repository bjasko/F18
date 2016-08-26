/*
 * This file is part of the bring.out knowhow ERP, a free and open source
 * Enterprise Resource Planning software suite,
 * Copyright (c) 1994-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_knowhow.md located at the
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */

#include "f18.ch"

STATIC picdem := "9999999999.99"

FUNCTION fin_kamate_obracun_sa_kamatni_list( cIdPartner, lPrintKamatniList, cVarObrac )

   LOCAL nKumKamSD := 0
   LOCAL cTxtPdv
   LOCAL cTxtUkupno
   LOCAL hParams := hb_Hash()
   LOCAL nOsnovSd
   LOCAL hRec
   LOCAL nOsnDug, nSKumKam

   IF lPrintKamatniList == NIL
      lPrintKamatniList := .T.
   ENDIF

   nGlavn := 2892359.28
   dDatOd := CToD( "01.02.92" )
   dDatDo := CToD( "30.09.96" )

   O_KS
   SELECT ks
   SET ORDER TO TAG "2"

   nStr := 0

   IF lPrintKamatniList

      nPdvTotal := nKamate * ( 17 / 100 )

      cTxtPdv := "PDV (17%)"
      cTxtPdv += " "
      cTxtPdv += Replicate( ".", 44 )
      cTxtPdv += Str( nPdvTotal, 12, 2 )
      cTxtPdv += " KM"

      cTxtUkupno := "Ukupno sa PDV"
      cTxtUkupno += " "
      cTxtUkupno += Replicate( ".", 40 )
      cTxtUkupno += Str( nKamate + nPdvTotal, 12, 2 )
      cTxtUkupno += " KM"

      ?
      P_10CPI
      ?? PadC( "- Strana " + Str( ++nStr, 4 ) + "-", 80 )
      ?

      SELECT partn
      HSEEK cIdPartner

      cPom := Trim( partn->adresa )

      IF !Empty( partn->telefon )
         cPom += ", TEL:" + partn->telefon
      ENDIF

      cPom := PadR( cPom, 42 )
      dDatPom := fin_kam_datum_obracuna()

   ENDIF

   SELECT kam_pripr
   SEEK cIdPartner

   IF lPrintKamatniList

      IF PRow() > 40
         FF
         ?
         P_10CPI
         ?? PadC( "- Strana " + Str( ++nStr, 4 ) + "-", 80 )
         ?
      ENDIF

      P_10CPI
      B_ON
      SELECT partn
      SEEK cIdPartner
      hRec := dbf_get_rec()
      SELECT kam_pripr

      ? PadC( "KAMATNI LIST KUPAC: " + Alltrim( hRec[ "id" ] + " - " + Alltrim( hRec[ "naz" ] )) + " " + DToC( fin_kam_datum_obracuna()), 80 )
      B_OFF

      IF fin_kam_prikaz_kumulativ() == "N"
         P_12CPI
      ELSE
         P_COND
      ENDIF

      ?
      ?
      ?

      IF cVarObrac == "Z"
         m := " ---------- -------- -------- --- ------------- ------------- -------- ------- -------------" + iif( fin_kam_prikaz_kumulativ() == "D", " -------------", "" )
      ELSE
         m := " ---------- -------- -------- --- ------------- ------------- -------- -------------" + iif( fin_kam_prikaz_kumulativ() == "D", " -------------", "" )
      ENDIF

      NStrana( "1" )

   ENDIF

   nSKumKam := 0
   nOsnovSD := 0
   SELECT kam_pripr
   cIdPartner := field->idpartner

   // IF !lPrintKamatniList
   nOsnDug := field->osndug
   // ENDIF

   DO WHILE !Eof() .AND. field->idpartner == cIdPartner

      fStampajBr := .T.
      fPrviBD := .T.
      nKumKamBD := 0
      nKumKamSD := 0
      cBrDok := field->brdok
      cM1 := field->m1
      nOsnovSD := kam_pripr->osnovica

      DO WHILE !Eof() .AND. field->idpartner == cIdpartner .AND. field->brdok == cBrdok

         dDatOd := kam_pripr->datod
         dDatdo := kam_pripr->datdo
         nOsnovSD := kam_pripr->osnovica

         IF fprviBD
            nGlavnBD := kam_pripr->osnovica
            fPrviBD := .F.
         ELSE

            IF cVarObrac == "Z"
               nGlavnBD := kam_pripr->osnovica + nKumKamSD
            ELSE
               nGlavnBD := kam_pripr->osnovica
            ENDIF
         ENDIF

         nGlavn := nGlavnBD

         SELECT ks
         SEEK DToS( dDatOd )

         IF dDatOd < field->DatOd .OR. Eof()
            SKIP -1
         ENDIF

         DO WHILE .T.

            dDDatDo := Min( field->DatDO, dDatDo )
            nPeriod := dDDatDo - dDatOd + 1

            IF ( cVarObrac == "P" )
               IF ( Prestupna( Year( dDatOd ) ) )
                  nExp := 366
               ELSE
                  nExp := 365
               ENDIF
            ELSE
               IF field->tip == "G"
                  IF field->duz == 0
                     nExp := 365
                  ELSE
                     nExp := field->duz
                  ENDIF
               ELSEIF field->tip == "M"
                  IF field->duz == 0
                     dExp := "01."
                     IF Month( ddDatdo ) == 12
                        dExp += "01." + AllTrim( Str( Year( dDDatdo ) + 1 ) )
                     ELSE
                        dExp += AllTrim( Str( Month( dDDatdo ) + 1 ) ) + "." + AllTrim( Str( Year( dDDatdo ) ) )
                     ENDIF
                     nExp := Day( CToD( dExp ) - 1 )
                  ELSE
                     nExp := field->duz
                  ENDIF
               ELSEIF field->tip == "3"
                  nExp := field->duz
               ELSE
                  nExp := field->duz
               ENDIF
            ENDIF

            IF field->den <> 0 .AND. dDatOd == field->datod
               IF lPrintKamatniList
                  ? "********* Izvrsena Denominacija osnovice sa koeficijentom:", den, "****"
               ENDIF
               nOsnovSD := Round( nOsnovSD * field->den, 2 )
               nGlavn := Round( nGlavn * field->den, 2 )
               nKumKamSD := Round( nKumKamSD * field->den, 2 )
            ENDIF

            IF ( cVarObrac == "Z" )
               nKKam := ( ( 1 + field->stkam / 100 ) ^ ( nPeriod / nExp ) - 1.00000 )
               nIznKam := nKKam * nGlavn
            ELSE
               nKStopa := field->stkam / 100
               cPom777 := my_get_from_ini( "KAM", "FormulaZaProstuKamatu", "nGlavn*nKStopa*nPeriod/nExp", KUMPATH )
               nIznKam := &( cPom777 )
            ENDIF

            nIznKam := Round( nIznKam, 2 )

            IF lPrintKamatniList

               IF PRow() > 55
                  FF
                  Nstrana()
               ENDIF

               IF fStampajbr
                  ? " " + cBrdok + " "
                  fStampajBr := .F.
               ELSE
                  ? " " + Space( 10 ) + " "
               ENDIF

               ?? dDatOd, dDDatDo

               @ PRow(), PCol() + 1 SAY nPeriod PICT "999"
               @ PRow(), PCol() + 1 SAY nOsnovSD PICT picdem
               @ PRow(), PCol() + 1 SAY nGlavn PICT picdem

               IF ( cVarObrac == "Z" )
                  @ PRow(), PCol() + 1 SAY field->tip
                  @ PRow(), PCol() + 1 SAY field->stkam PICT "999.99"
                  @ PRow(), PCol() + 1 SAY nKKam * 100 PICT "9999.99"
               ELSE
                  @ PRow(), PCol() + 1 SAY field->stkam PICT "999.99"
               ENDIF

               nCol1 := PCol() + 1
               @ PRow(), PCol() + 1 SAY nIznKam PICT picdem

            ENDIF

            IF ( cVarObrac == "Z" )
               nGlavnBD += nIznKam
            ENDIF

            nKumKamBD += nIznKam
            nKumKamSD += nIznKam

            IF ( cVarObrac == "Z" )
               nGlavn += nIznKam
            ENDIF

            IF lPrintKamatniList .AND. fin_kam_prikaz_kumulativ() == "D"
               @ PRow(), PCol() + 1 SAY nKumKamSD PICT picdem
            ENDIF

            IF dDatDo <= field->DatDo
               SELECT kam_pripr
               EXIT
            ENDIF

            SKIP

            IF Eof()
               error_bar( "KAM_OBR", "PARTNER: " + kam_pripr->idpartner + ", BR.DOK.: " + kam_pripr->brdok + ;
                  "#GRESKA : Fali datumski interval u kam.stopama!" )
               EXIT
            ENDIF

            dDatOd := field->DatOd

         ENDDO

         SELECT kam_pripr
         SKIP

      ENDDO

      nKumKamSD := fin_kam_iznos_na_dan( nKumKamSD, fin_kam_datum_obracuna(), iif( Empty( cM1 ), KS->datdo, KS2->datdo ), cM1 )

      IF lPrintKamatniList
         IF PRow() > 59
            FF
            Nstrana()
         ENDIF
         ? m
         ? " UKUPNO ZA", cBrdok
         @ PRow(), nCol1 SAY nKumKamBD PICT picdem

         ? " UKUPNO NA DAN", fin_kam_datum_obracuna(), ":"
         @ PRow(), nCol1 SAY nKumKamSD PICT picdem
         ? m
      ENDIF

      nSKumKam += nKumKamSD

      SELECT kam_pripr

   ENDDO

   IF lPrintKamatniList

      IF PRow() > 54
         FF
         NStrana()
      ENDIF

      ? m
      ? " SVEUKUPNO KAMATA NA DAN " + DToC( fin_kam_datum_obracuna() ) + ":"
      @ PRow(), PCol() SAY nOsnDug PICT picdem
      @ PRow(), nCol1  SAY nSKumKam PICT picdem
      ? m

      P_10CPI

      IF PRow() < 62 + dodatni_redovi_po_stranici()
         FOR i := 1 TO 62 + dodatni_redovi_po_stranici() - PRow()
            ?
         NEXT
      ENDIF

      _potpis()

      FF


      SELECT Partn
      HSEEK PadR( gFirma, 6 )
      hRec := dbf_get_rec()
      hParams[ "naziv" ] := hRec[ "naz" ]
      hParams[ "adresa" ] :=  hRec[ "adresa" ]
      hParams[ "tel" ] := hRec[ "telefon" ]
      hParams[ "fax" ] := hRec[ "fax" ]
      hParams[ "idbr" ] := get_partn_idbr( PadR( gFirma, 6 ) )
      hParams[ "mjesto" ] := hRec[ "mjesto" ]
      hParams[ "ptt" ] := hRec[ "ptt" ]
      hParams[ "ziror" ] := hRec[ "ziror" ]
      hParams[ "datum" ] := fin_kam_datum_obracuna()

      SELECT Partn
      HSEEK cIdPartner
      hRec := dbf_get_rec()
      hParams[ "kupac_1" ] := hRec[ "id" ] + " - " + hRec[ "naz" ]
      hParams[ "kupac_2" ] := hRec[ "ptt" ] + " " + hRec[ "mjesto" ]
      hParams[ "kupac_3" ] := hRec[ "adresa" ]
      hParams[ "kupac_idbr" ] := get_partn_idbr( cIdPartner )

      hParams[ "osndug" ] := nOsnDug
      hParams[ "kamate" ] := nSKumKam

      print_opomena_pred_tuzbu( hParams )


      IF PRow() < 62 + dodatni_redovi_po_stranici()
         FOR i := 1 TO 62 + dodatni_redovi_po_stranici() - PRow()
            ?
         NEXT
      ENDIF

      _potpis()
      SELECT kam_pripr
   ENDIF

   // IF !lPrintKamatniList
   nKamate := nSKumKam
   // ENDIF

   RETURN nSKumKam



STATIC FUNCTION _potpis()

   ?  PadC( "     Obradio:                                 Direktor:    ", 80 )
   ?
   ?  PadC( "_____________________                    __________________", 80 )
   ?

   RETURN .T.



STATIC FUNCTION NStrana( cTip, cVarObrac )

   IF cTip == NIL
      cTip := ""
   ENDIF

   IF cTip == ""
      ?
      P_10CPI
      ?? PadC( "- Strana " + Str( ++nStr, 4 ) + "-", 80 )
      ?
   ENDIF

   IF cTip == "1" .OR. cTip = ""

      IF fin_kam_prikaz_kumulativ() == "N"
         P_12CPI
      ELSE
         P_COND
      ENDIF

      ? m

      IF cVarObrac == "Z"
         ? "   Broj          Period      dana     ostatak       kamatna   Tip kam  Konform.    Iznos    " + IF( fin_kam_prikaz_kumulativ() == "D", "   kumulativ   ", "" )
         ? "  racuna                              racuna       osnovica   i stopa   koef       kamate   " + IF( fin_kam_prikaz_kumulativ() == "D", "    kamate     ", "" )
      ELSE
         ? "   Broj          Period      dana     ostatak       kamatna    Stopa       Iznos    " + IF( fin_kam_prikaz_kumulativ() == "D", "   kumulativ   ", "" )
         ? "  racuna                              racuna       osnovica                kamate   " + IF( fin_kam_prikaz_kumulativ() == "D", "    kamate     ", "" )
      ENDIF

      ? m

   ENDIF

   RETURN .T.



FUNCTION fin_kam_iznos_na_dan( nIznos, dTrazeni, dProsli, cM1 )

   // * dtrazeni = 30.06.98
   // * dprosli  = 15.05.94
   // * znaci: uracunaj sve denominacije od 15.05.94 do 30.06.98
   LOCAL nK := 1

   PushWA()
   SELECT KS
   GO TOP
   DO WHILE !Eof()
      IF DToS( dTrazeni ) < DToS( DatOd )
         EXIT
      ELSEIF DToS( dProsli ) >= DToS( DatOd )
         SKIP 1
         LOOP
      ENDIF
      IF field->den <> 0
         nK := nK * field->den
      ENDIF
      SKIP 1
   ENDDO
   PopWA()

   RETURN nIznos * nK