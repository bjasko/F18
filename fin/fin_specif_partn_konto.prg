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


FUNCTION fin_spec_partnera_na_kontu()

   LOCAL nCol1

   picBHD := FormPicL( "9 " + gPicBHD, 17 )

   cF := cDD := "2"
   // format izvjestaja
   cPG := "D"
   // prikazi grad partnera
   cIdFirma := gFirma
   nIznos := nIznos2 := 0
   cDP := "1"
   qqKonto := qqPartner := Space( 100 )

   O_PARTN

   Box( "skpoi", 10, 70, .F. )
   @ m_x + 1, m_y + 2 SAY "SPECIFIKACIJA PARTNERA NA KONTU"
   IF gNW == "D"
      @ m_x + 3, m_y + 2 SAY "Firma "; ?? gFirma, "-", gNFirma
   ELSE
      @ m_x + 3, m_y + 2 SAY "Firma: " GET cIdFirma valid {|| P_Firma( @cIdFirma ), cidfirma := Left( cidfirma, 2 ), .T. }
   ENDIF
   @ m_x + 4, m_y + 2 SAY "Konto  " GET qqKonto PICTURE "@!S50"
   @ m_x + 5, m_y + 2 SAY "Partner" GET qqPartner PICTURE "@!S50"
   @ m_x + 6, m_y + 2 SAY "Duguje/Potrazuje (1/2) ?" GET cDP PICTURE "@!" VALID cDP $ "12"
   @ m_x + 7, m_y + 2 SAY "IZNOS " + ValDomaca() GET nIznos  PICTURE '999999999999.99'
   IF fin_dvovalutno()
      @ m_x + 8, m_y + 2 SAY "IZNOS " + ValPomocna() GET nIznos2 PICTURE '9999999999.99'
   ENDIF
   @ m_x + 9, m_y + 2 SAY "Format izvjestaja A3/A4 (1/2) :" GET cF VALID cF $ "12"
   @ m_x + 10, m_y + 2 SAY "Prikazi grad partnera (D/N) :" GET cPG PICT "@!" VALID cPG $ "DN"
   READ
   IF cF == "2"
      IF fin_dvovalutno()
         @ m_x + 10, m_y + 40 SAY AllTrim( ValDomaca() ) + "/" + AllTrim( ValPomocna() ) + " (1/2):" GET cDD VALID cDD $ "12"
         READ
      ELSE
         cDD := "1"
      ENDIF
   ENDIF

   DO WHILE .T.
      READ; ESC_BCR
      aUsl1 := Parsiraj( qqKonto, "IdKonto", "C" )
      aUsl2 := Parsiraj( qqPartner, "IdPartner", "C" )
      IF aUsl1 <> NIL .AND. aUsl2 <> NIL;  exit; ENDIF
   ENDDO

   BoxC()

   B := 0

   cIdFirma := Left( cIdFirma, 2 )

   IF cF == "1"
      M := "----- " + Replicate( "-", FIELD_PARTNER_ID_LENGTH ) + " ------------------------------------ ----------------------- ------------------ ----------------- ----------------- ----------------- ----------------- ----------------- ----------------- -----------------"
   ELSEIF cPG == "D"
      M := "---- " + Replicate( "-", FIELD_PARTNER_ID_LENGTH ) + " ------------------------- ---------------- ----------------- ----------------- ----------------- -----------------"
   ELSE
      M := "---- " + Replicate( "-", FIELD_PARTNER_ID_LENGTH ) + " ------------------------- ----------------- ----------------- ----------------- -----------------"
   ENDIF
   O_SUBAN
   SELECT SUBAN
   PRIVATE cFilt1 := "IdFirma=='" + cIdFirma + "'.and." + aUsl1 + ".and." + aUsl2
   SET FILTER to &cFilt1


   GO TOP
   EOF CRET

   nStr := 0
   START PRINT CRET
   DO WHILE !Eof()
      nSD1DEM := nSP1DEM := nSD1BHD := nSP1BHD := 0

      cIdKonto := IdKonto
      IF PRow() <> 0; FF; ZaglDPK(); ENDIF

      nUkDugBHD := nUkPotBHD := nUkDugDEM := nUkPotDEM := 0
      DO WHILE !Eof() .AND. cIdKonto = IdKonto // konto

         cIdPartner := IdPartner

         nDugBHD := nPotBHD := nDugDEM := nPotDEM := 0
         DO WHILE  !Eof() .AND. cIdKonto = IdKonto .AND. cIdPartner == IdPartner
            IF D_P = "1"
               nDugBHD += IznosBHD; nDugDEM += IznosDEM
            ELSE
               nPotBHD += IznosBHD; nPotDEM += IznosDEM
            ENDIF
            SKIP
         ENDDO

         nRazl := nDugBHD - nPotBHD
         nRazl2 := nDugDEM - nPotDEM
         IF cDP == "2"
            nRazl := -nRazl; nRazl2 := -nRazl2
         ENDIF

         IF ( nIznos == 0 .OR. ( nRazl > nIznos ) )  .AND. ( nIznos2 == 0 .OR. ( nRazl2 > nIznos2 ) )


            IF PRow() == 0  // ako je nRazl=0 uzeti sve partnere
               ZaglDPK()
            ENDIF

            IF PRow() > 60 + dodatni_redovi_po_stranici()
               FF
               ZaglDPK()
            ENDIF

            @ PRow() + 1, 0 SAY ++B PICTURE '9999'
            @ PRow(), 5 SAY cIdPartner

            SELECT PARTN
            HSEEK cIdPartner

            @ PRow(), PCol() + 1 SAY PadR( naz, 25 )

            IF cF == "1" // a3 format

               @ PRow(), PCol() + 1 SAY PadR( naz2, 25 ) PICT 'XXXXXXXXXXXX'
               @ PRow(), PCol() + 1 SAY PTT
               @ PRow(), PCol() + 1 SAY PadR( Mjesto, 16 ) PICT 'XXXXXXXXXXXXXXXX'

            ELSEIF cPG == "D"

               @ PRow(), PCol() + 1 SAY PadR( Mjesto, 16 ) PICT 'XXXXXXXXXXXXXXXX'
            ENDIF

            nCol1 := PCol()

            IF cF == "1" .OR. cDD = "1"
               @ PRow(), PCol() + 1 SAY nDugBHD PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nPotBHD PICTURE picBHD
            ENDIF
            IF cF == "1" .OR. cDD = "2"
               @ PRow(), PCol() + 1 SAY nDugDEM PICTURE picbhd
               @ PRow(), PCol() + 1 SAY nPotDEM PICTURE picbhd
            ENDIF
            nUkDugBHD += nDugBHD
            nUkDugDEM += nDugDEM
            nUkPotBHD += nPotBHD
            nUkPotDEM += nPotDEM

            nSDBHD := nDugBHD - nPotBHD
            nSDDEM := nDugDEM - nPotDEM

            IF nSDBHD >= 0
               nSPBHD := 0; nSPDEM := 0
            ELSE
               nSPBHD := -nSDBHD; nSPDEM := -nSDDEM
               nSDBHD := nSDDEM := 0
            ENDIF

            IF cF == "1" .OR. cDD = "1"
               @ PRow(), PCol() + 1 SAY nSDBHD PICTURE picBHD
               @ PRow(), PCol() + 1 SAY nSPBHD PICTURE picBHD
            ENDIF
            IF cF == "1" .OR. cDD = "2"
               @ PRow(), PCol() + 1 SAY nSDDEM PICTURE picbhd
               @ PRow(), PCol() + 1 SAY nSPDEM PICTURE picbhd
            ENDIF

            nSD1DEM += nSDDEM; nSP1DEM += nSPDEM
            nSD1BHD += nSDBHD; nSP1BHD += nSPBHD
            SELECT SUBAN

         ENDIF


      ENDDO // konto

      IF PRow() > 60 + dodatni_redovi_po_stranici(); FF; ZaglDPK(); ENDIF
      ?  M
      ? "UKUPNO ZA KONTO:"
      @ PRow(), nCol1 SAY ""
      IF cF == "1" .OR. cDD == "1"
         @ PRow(), PCol() + 1      SAY nUkDugBHD PICTURE picBHD
         @ PRow(), PCol() + 1 SAY nUkPotBHD PICTURE picBHD
      ENDIF
      IF cF == "1" .OR. cDD == "2"
         @ PRow(), PCol() + 1 SAY nUkDugDEM PICTURE picbhd
         @ PRow(), PCol() + 1 SAY nUkPotDEM PICTURE picbhd
      ENDIF

      nCol2 := PCol()

      IF cF == "1" .OR. cDD = "1"
         @ PRow(), PCol() + 1 SAY nSD1BHD PICTURE picBHD // dug bhd ukupno
         @ PRow(), PCol() + 1 SAY nSP1BHD PICTURE picBHD // pot bhd ukupno
      ENDIF

      IF cF == "1" .OR. cDD = "2"
         @ PRow(), PCol() + 1 SAY nSD1DEM PICTURE picbhd // dug dem ukupno
         @ PRow(), PCol() + 1 SAY nSP1DEM PICTURE picbhd // pot dem ukupno
      ENDIF
      ? M
      @ PRow() + 1, nCol2 SAY ""

      IF cF == "1" .OR. cDD = "1"
         nSaldo := nUkDugBHD - nUkPotBHD
         @ PRow(), PCol() + 1 SAY iif( nSaldo >= 0, nSaldo, 0 ) PICTURE picBHD // dug bhd
         nSaldo := nUkPotBHD - nUkDugBHD
         @ PRow(), PCol() + 1 SAY iif( nSaldo >= 0, nSaldo, 0 ) PICTURE picBHD // pot bhd
      ENDIF

      IF cF == "1" .OR. cDD = "2"
         nSaldo := nUkDugDEM - nUkPotDEM
         @ PRow(), PCol() + 1 SAY iif( nSaldo >= 0, nSaldo, 0 ) PICTURE picbhd // dug dem
         nSaldo := nUkPotDEM - nUkDugDEM
         @ PRow(), PCol() + 1 SAY iif( nSaldo >= 0, nSaldo, 0 ) PICTURE picbhd // pot dem
      ENDIF
      ? M


   ENDDO // eof()

   FF
   ENDPRINT

   closeret

   RETURN




/*! \fn ZaglDPK()
 *  \brief Zaglavlje specifikacije partnera po kontu
 */

FUNCTION ZaglDPK()

   ?
   P_COND
   ?? "FIN.P: SPECIFIKACIJA "
   @ PRow(), PCol() + 2 SAY ""
   IF !Empty( qqPartner )
      ?? " PARTNERA:", Trim( qqpartner ), "  "
   ELSE
      ?? " SVIH PARTNERA  "
   ENDIF
   IF nIznos <> 0
      IF cDP == "1"
         ?? "KOJI DUGUJU PREKO", nIznos, AllTrim( ValDomaca() )
      ELSE
         ?? "KOJI POTRA�UJU PREKO", nIznos, AllTrim( ValDomaca() )
      ENDIF
   ELSEIF nIznos2 <> 0
      IF cDP == "1"
         ?? "KOJI DUGUJU PREKO", nIznos2, AllTrim( ValPomocna() )
      ELSE
         ?? "KOJI POTRA�UJU PREKO", nIznos2, AllTrim( ValPomocna() )
      ENDIF
   ENDIF
   ?? "  NA DAN :", Date()
   IF cF == "1"
      @ PRow(), 200 SAY "Str:" + Str( ++nStr, 3 )
   ELSE
      @ PRow(), 100 SAY "Str:" + Str( ++nStr, 3 )
      IF cDD == "1"
         @ PRow() + 1, 4 SAY "*** OBRA�UN ZA " + ValDomaca() + "****"
      ELSE
         @ PRow() + 1, 4 SAY "*** OBRA�UN ZA " + ValPomocna() + "****"
      ENDIF
   ENDIF
   @ PRow() + 1, 0 SAY " FIRMA:"
   @ PRow(), PCol() + 2 SAY cIdFirma
   SELECT PARTN; HSEEK cIdFirma
   @ PRow(), PCol() + 1 SAY AllTrim( PadR( naz, 25 ) ); @ PRow(), PCol() + 1 SAY naz2

   @ PRow(), PCol() + 2 SAY "KONTO:"; @ PRow(), PCol() + 2 SAY cIdKonto
   IF cF == "1"
      ? "----- " + Replicate( "-", FIELD_PARTNER_ID_LENGTH ) + " ------------------------------------ ----- ----------------- ----------------------------------------------------------------------- -----------------------------------------------------------------------"
      ? "*RED.*" + PadC( "�IFRA", FIELD_PARTNER_ID_LENGTH ) + "*     NAZIV POSLOVNOG PARTNERA      * PTT *      MJESTO     *       K  U  M  U  L  A  T  I  V  N  I       P  R  O  M  E  T           *                 S      A      L      D       O                       *"
      ? "      " + REPL( " ", FIELD_PARTNER_ID_LENGTH ) + "                                                              ----------------------------------------------------------------------- -----------------------------------------------------------------------"
      ? "*BROJ*" + Replicate( " ", FIELD_PARTNER_ID_LENGTH ) + "*                                   * BROJ*                 *   DUGUJE   " + ValDomaca() + "  *  POTRA�UJE " + ValDomaca() + " *   DUGUJE  " + ValPomocna() + "  *   POTRA�. " + ValPomocna() + "  *    DUGUJE " + ValDomaca() + "  *  POTRA�UJE " + ValDomaca() + " *   DUGUJE  " + ValPomocna() + "  *   POTRA�." + ValPomocna() + "  *"
      ? m
   ELSEIF cPG == "D"
      ? "----- " + Replicate( "-", FIELD_PARTNER_ID_LENGTH ) + " ------------------------ ---------------- ----------------------------------- -----------------------------------"
      ? "*RED.*" + PadC( "�IFRA", FIELD_PARTNER_ID_LENGTH ) + "*     NAZIV POSLOVNOG    *     MJESTO     *         KUMULATIVNI  PROMET       *               SALDO              *"
      ? "                                                       ----------------------------------- -----------------------------------"
      ? "*BROJ*" + Replicate( " ", FIELD_PARTNER_ID_LENGTH )  + "*     PARTNERA           *                *    DUGUJE       *   POTRA�UJE     *    DUGUJE       *   POTRA�UJE    *"
      ? m
   ELSE
      ? "----- " + Replicate( "-", FIELD_PARTNER_ID_LENGTH ) + " ------------------------ ----------------------------------- -----------------------------------"
      ? "*RED.*" + PadC( "SIFRA", FIELD_PARTNER_ID_LENGTH ) + "*      NAZIV POSLOVNOG    *         KUMULATIVNI  PROMET       *               SALDO              *"
      ? "      " + REPL( " ", FIELD_PARTNER_ID_LENGTH ) + "                        ----------------------------------- -----------------------------------"
      ? "*BROJ*" + Replicate( " ", FIELD_PARTNER_ID_LENGTH ) + "*      PARTNERA           *    DUGUJE       *   POTRA�UJE     *    DUGUJE       *   POTRA�UJE    *"
      ? m
   ENDIF


   SELECT SUBAN

   RETURN .T.