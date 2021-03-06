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



FUNCTION os_pregled_amortizacije()

   LOCAL _sr_id, _sr_id_rj, _sr_id_am, _sr_dat_otp, _sr_datum
   LOCAL cIdKonto := qidkonto := Space( 7 ), cidsk := "", ndug := ndug2 := npot := npot2 := ndug3 := npot3 := 0
   LOCAL nCol1 := 10
   LOCAL _mod_name := "OS"
   LOCAL nTNab, nTOtp, nTAmortizacijaP
   LOCAL _sanacija := .F.

   IF gOsSii == "S"
      _mod_name := "SII"
   ENDIF

   //o_konto()
   o_rj()

   o_os_sii_promj()
   o_os_sii()

   cIdRj := Space( 4 )
   cPromj := "2"
   cPocinju := "N"
   cKPocinju := "N"
   cFiltSadVr := "0"
   cFiltK1 := Space( 40 )
   cON := " " // novo!

   cBrojSobe := Space( 6 )
   lBrojSobe := .F.

   cPotpis := "N"

   Box(, 13, 77 )
   DO WHILE .T.
      @ box_x_koord() + 1, box_y_koord() + 2 SAY "Radna jedinica (prazno - svi):" GET cIdRj ;
         VALID {|| Empty( cIdRj ) .OR. P_RJ( @cIdRj ), if( !Empty( cIdRj ), cIdRj := PadR( cIdRj, 4 ), .T. ), .T. }

      @ box_x_koord() + 1, Col() + 2 SAY "sve koje pocinju " GET cPocinju VALID cPocinju $ "DN" PICT "@!"
      @ box_x_koord() + 2, box_y_koord() + 2 SAY "Konto (prazno - svi):" GET qIdKonto PICT "@!" VALID Empty( qidkonto ) .OR. P_Konto( @qIdKonto )
      @ box_x_koord() + 2, Col() + 2 SAY "sva koja pocinju " GET cKpocinju VALID cKpocinju $ "DN" PICT "@!"
      @ box_x_koord() + 4, box_y_koord() + 2 SAY "Za sredstvo prikazati vrijednost:"
      @ box_x_koord() + 5, box_y_koord() + 2 SAY "1 - bez promjena"
      @ box_x_koord() + 6, box_y_koord() + 2 SAY "2 - osnovni iznos + promjene"
      @ box_x_koord() + 7, box_y_koord() + 2 SAY "3 - samo promjene           " GET cPromj VALID cpromj $ "123"
      @ box_x_koord() + 8, box_y_koord() + 2 SAY "Filter po sadasnjoj vr.(0-sve,1-samo koja je imaju,2-samo koja je nemaju):" GET cFiltSadVr VALID cFiltSadVr $ "012" PICT "9"
      @ box_x_koord() + 9, box_y_koord() + 2 SAY "Filter po grupaciji K1:" GET cFiltK1 PICT "@!S20"
      IF os_sii_da_li_postoji_polje( "brsoba" )
         lBrojSobe := .T.
         @ box_x_koord() + 10, box_y_koord() + 2 SAY "Broj sobe (prazno sve) " GET cBrojSobe  PICT "@!"
      ENDIF
      @ box_x_koord() + 11, box_y_koord() + 2 SAY "Prikaz svih os ( )      /   neotpisanih (N)     / otpisanih   (O) "
      @ box_x_koord() + 12, box_y_koord() + 2 SAY "/novonabavljenih   (B) / iz proteklih godina (G)" GET cON VALID con $ "ONBG " PICT "@!"
      @ box_x_koord() + 13, box_y_koord() + 2 SAY "Prikazati mjesta za potpis na kraju pregleda? (D/N)" GET cPotpis VALID cPotpis $ "DN" PICT "@!"
      read; ESC_BCR
      aUsl1 := Parsiraj( cFiltK1, "K1" )
      IF aUsl1 <> NIL; exit; ENDIF
   ENDDO
   BoxC()

   cIdRj := PadR( cIdRj, 4 )

   IF Empty( qidkonto )
     qidkonto := ""
   ENDIF
   IF cKPocinju == "D"
      qIdKonto := Trim( qIdKonto )
   ENDIF

   IF Empty( cIdRj ); cIdRj := ""; ENDIF
   IF cPocinju == "D"
      cIdRj := Trim( cIdRj )
   ENDIF

   os_rpt_default_valute()

   START PRINT CRET

   PRIVATE nStr := 0
   // strana
   select_o_rj( cIdRj )
   select_o_os_or_sii()

   P_10CPI
   ? tip_organizacije() + ":", self_organizacija_naziv()

   IF !Empty( cIdRj )
      ? "Radna jedinica:", cIdRj, rj->naz
   ENDIF

   ? _mod_name + ": Pregled obracuna amortizacije po kontima "

   ?? "", PrikazVal(), "    Datum:", os_datum_obracuna()

   IF !Empty( cFiltK1 )
      ? "Filter grupacija K1 pravljen po uslovu: '" + Trim( cFiltK1 ) + "'"
   ENDIF

   P_COND2

   PRIVATE m := "----- ---------- ---- -------- ------------------------------ --- ------" + REPL( " " + REPL( "-", Len( gPicI ) ), 5 )

   cFilter := ".t."

   IF !Empty( cFiltK1 )
      cFilter += ".and." + aUsl1
   ENDIF

   IF cPocinju == "D" .AND. !Empty( qIdKonto )
      cFilter += ".and. idkonto=qIdKonto .and. idrj=cIdRj"
   ENDIF

   IF lBrojSobe .AND. !Empty( cBrojSobe )
      cFilter += ".and. brsoba==cBrojSobe"
   ENDIF

   IF !cFilter == ".t."
      select_o_os_or_sii()
      SET FILTER TO &cFilter
   ENDIF

   IF Empty( cIdRj ) .OR. cPocinju == "D"
      select_o_os_or_sii()
      SET ORDER TO TAG "4"
      // "OSi4","idkonto+idrj+id"
      SEEK qidkonto
   ELSE
      select_o_os_or_sii()
      SET ORDER TO TAG "3"
      // "OSi3","idrj+idkonto+id"
      SEEK cIdRj + qIdkonto
   ENDIF

   PRIVATE nRbr := 0

   nDug := nPot1 := nPot2 := 0

   os_zagl_amort()

   nA1 := 0
   nA2 := 0

   DO WHILE !Eof() .AND. ( field->idrj = cIdRj .OR. Empty( cIdRj ) )

      cIdSK := Left( idkonto, 3 )
      nDug2 := nPot21 := nPot22 := 0
      nTNab := nTOtp := nTAmortizacijaP := 0
      _sanacija := .F.

      DO WHILE !Eof() .AND. ( idrj = cIdRj .OR. Empty( cIdRj ) )  .AND. Left( idkonto, 3 ) == cidsk

         cIdKonto := idkonto
         nDug3 := nPot31 := nPot32 := 0
         nTNab := nTOtp := nTAmortizacijaP := 0

         DO WHILE !Eof() .AND. ( idrj = cIdRj .OR. Empty( cIdRj ) )  .AND. idkonto == cidkonto

            IF PRow() > RPT_PAGE_LEN
               FF
               os_zagl_amort()
            ENDIF

            IF !( ( cON == "N" .AND. datotp_prazan() ) .OR. ;
                  ( con == "O" .AND. !datotp_prazan() ) .OR. ;
                  ( con == "B" .AND. Year( datum ) = Year( os_datum_obracuna() ) ) .OR. ;
                  ( con == "G" .AND. Year( datum ) < Year( os_datum_obracuna() ) ) .OR. ;
                  Empty( con ) )
               SKIP 1
               LOOP
            ENDIF

            fIma := .T.

            IF cPromj == "3"
               // ako zelim samo promjene vidi ima li za sr.
               // uopste promjena
               _sr_id := field->id
               os_select_promj( _sr_id )
               //HSEEK _sr_id
               fIma := .F.
               DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
                  fIma := .T.
                  SKIP
               ENDDO
               select_o_os_or_sii()
            ENDIF

            // utvrdjivanje da li sredstvo ima sada�nju vrijednost
            // --------------------------------------------------

            lImaSadVr := .F.

            IF cPromj <> "3"
               IF nabvr - otpvr - amp > 0
                  lImaSadVr := .T.
               ENDIF
            ENDIF

            IF cPromj $ "23"
               // prikaz promjena
               _sr_id := field->id
               os_select_promj( _sr_id )
               //HSEEK _sr_id
               DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
                  nA1 := 0
                  nA2 := amp
                  IF nabvr - otpvr - amp > 0
                     lImaSadVr := .T.
                  ENDIF
                  SKIP
               ENDDO
               select_o_os_or_sii()
            ENDIF

            // ispis stavki
            // ------------
            IF cFiltSadVr == "1" .AND. !( lImaSadVr ) .OR. ;
                  cFiltSadVr == "2" .AND. lImaSadVr
               SKIP
               LOOP
            ELSE
               IF fIma
                  ? Str( ++nrbr, 4 ) + ".", id, idrj, datum, naz, jmj, Str( kolicina, 6, 1 )
                  nCol1 := PCol() + 1
               ENDIF
               IF cPromj <> "3"
                  @ PRow(), ncol1    SAY nabvr * nBBK PICT gpici
                  @ PRow(), PCol() + 1 SAY otpvr * nBBK PICT gpici
                  @ PRow(), PCol() + 1 SAY amp * nBBK PICT gpici
                  @ PRow(), PCol() + 1 SAY otpvr * nBBK + amp * nBBK PICT gpici
                  @ PRow(), PCol() + 1 SAY nabvr * nBBK - otpvr * nBBK - amp * nBBK PICT gpici
                  nDug3 += nabvr
                  nPot31 += otpvr
                  nPot32 += amp
                  nTNab += nabvr
                  nTOtp += otpvr
                  nTAmortizacijaP += amp
               ENDIF
               IF cPromj $ "23"  // prikaz promjena
                  _sr_id := field->id
                  _sr_id_rj := field->idrj
                  os_select_promj( _sr_id )
                  //HSEEK _sr_id
                  DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()

                     ? Space( 5 ), Space( Len( id ) ), Space( Len( _sr_id_rj ) ), datum, opis

                     nA1 := 0
                     nA2 := amp

                     IF Left( field->opis, 2 ) == "#S"
                        _sanacija := .T.
                        nTAmortizacijaP += amp
                        nTOtp += otpvr
                        nTNab += nabvr
                     ENDIF

                     @ PRow(), ncol1    SAY nabvr * nBBK PICT gpici
                     @ PRow(), PCol() + 1 SAY otpvr * nBBK PICT gpici

                     IF !_sanacija
                        @ PRow(), PCol() + 1 SAY amp * nBBK PICT gpici
                        @ PRow(), PCol() + 1 SAY otpvr * nBBK + amp * nBBK PICT gpici
                        @ PRow(), PCol() + 1 SAY nabvr * nBBK - amp * nBBK - otpvr * nBBK PICT gpici
                     ENDIF

                     nDug3 += nabvr; nPot31 += otpvr
                     nPot32 += amp
                     SKIP
                  ENDDO

                  select_o_os_or_sii()

               ENDIF

            ENDIF

            SKIP

            IF _sanacija
               // ispisati stanje sanacija ako treba....
               ? Space( 20 ) + Replicate( "-", 88 )
               ? PadL( "Ukupni obracun sanacija:", nCol1 )
               @ PRow(), nCol1 SAY nTNab PICT gPicI
               @ PRow(), PCol() + 1 SAY nTOtp PICT gPicI
               @ PRow(), PCol() + 1 SAY nTAmortizacijaP PICT gPicI
               ?
               _sanacija := .F.
            ENDIF

         ENDDO

         IF PRow() > RPT_PAGE_LEN
            FF
            os_zagl_amort()
         ENDIF

         nTArea := Select()
         select_o_konto( cIdKonto )
         SELECT ( nTArea )
         ? m
         ? " ukupno ", cIdKonto, PadR( konto->naz, 50 )
         @ PRow(), ncol1    SAY ndug3 * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY npot31 * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY npot32 * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY npot31 * nBBK + npot32 * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY ndug3 * nBBK - npot31 * nBBK - npot32 * nBBK PICT gpici
         ? m
         nDug2 += nDug3; nPot21 += nPot31; nPot22 += nPot32
         IF !Empty( qidkonto ) .AND. cKPocinju == "N"
            EXIT
         ENDIF
      ENDDO
      IF !Empty( qidkonto ) .AND. cKPocinju == "N"
         EXIT
      ENDIF
      IF PRow() > RPT_PAGE_LEN; FF; os_zagl_amort(); ENDIF
      ? m
      nTArea := Select()
      select_o_konto( cIdSK )

      SELECT ( nTArea )
      ? " UKUPNO ", cIdSK, PadR( konto->naz, 50 )
      @ PRow(), ncol1    SAY ndug2 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY npot21 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY npot22 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY npot21 * nBBK + npot22 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY ndug2 * nBBK - npot21 * nBBK - npot22 * nBBK PICT gpici
      ? m
      nDug += nDug2; nPot1 += nPot21; nPot2 += nPot22

   ENDDO

   IF Empty( qidkonto ) .OR. cKPocinju == "D"
      IF PRow() > RPT_PAGE_LEN
         FF
         os_zagl_amort()
      ENDIF
      ?
      ? m
      ? " U K U P N O :"
      @ PRow(), ncol1    SAY ndug * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY npot1 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY npot2 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY npot1 * nBBK + npot2 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY ndug * nBBK - npot1 * nBBK - npot2 * nBBK PICT gpici
      ? m
      ?
      ?
      IF cPotpis == "D"
         ? " Zaduzeno lice:"
         ? " _______________________"
         ? Space( 95 ) + "Clanovi komisije:"
         ? Space( 95 ) + "_____________________"
         ? Space( 95 ) + "_____________________"
         ? Space( 95 ) + "_____________________"
      ENDIF
   ENDIF

   FF
   ENDPRINT

   my_close_all_dbf()

   RETURN


FUNCTION os_zagl_amort()

   ?
   @ PRow(), 125 SAY "Str." + Str( ++nStr, 3 )
   IF lBrojSobe .AND. !Empty( cBrojSobe )
      ?
      ? "Prikaz za sobu br:", cBrojSobe
      ?
   ENDIF
   IF con = "N"
      ? "PRIKAZ NEOTPISANIH SREDSTAVA:"
   ELSEIF con == "B"
      ? "PRIKAZ NOVONABAVLJENIH SREDSTAVA:"
   ELSEIF con == "G"
      ? "PRIKAZ SREDSTAVA IZ PROTEKLIH GODINA:"
   ELSEIF con == "O"
      ? "PRIKAZ OTPISANIH SREDSTAVA:"
   ELSEIF   con == " "
      ? "PRIKAZ SVIH SREDSTAVA:"
   ENDIF
   ? m
   ? " Rbr.  Inv.broj   RJ    Datum    Sredstvo                     jmj  kol  " + " " + PadC( "NabVr", Len( gPicI ) ) + " " + PadC( "OtpVr", Len( gPicI ) ) + " " + PadC( "Amort.", Len( gPicI ) ) + " " + PadC( "O+Am", Len( gPicI ) ) + " " + PadC( "SadVr", Len( gPicI ) )
   ? m

   RETURN
