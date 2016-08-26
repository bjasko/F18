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


// -------------------------------------------
// pregled sredstava po kontima
// -------------------------------------------
FUNCTION os_pregled_po_kontima()

   LOCAL _sr_id, _sr_id_rj, _sr_id_am, _sr_dat_otp, _sr_datum
   LOCAL cIdKonto := Space( 7 )
   LOCAL qIdKonto := Space( 7 )
   LOCAL cIdSk := ""
   LOCAL nDug := 0
   LOCAL nDug2 := 0
   LOCAL nPot := 0
   LOCAL nPot2 := 0
   LOCAL nDug3 := 0
   LOCAL nPot3 := 0
   LOCAL nCol1 := 10
   LOCAL nKontoLen := 3
   LOCAL _mod_name := "OS"

   IF gOsSii == "S"
      _mod_name := "SII"
   ENDIF

   O_KONTO
   O_RJ

   o_os_sii_promj()
   o_os_sii()

   cIdrj := Space( 4 )
   cAmoGr := "N"
   cON := "N"
   cPromj := "2"
   cDodaj := "1"
   cPocinju := "N"
   dDatOd := CToD( "" )
   dDatDo := Date()
   cDatper := "N"
   cIzbUbac := "I"
   cFiltSadVr := "0"
   cFiltK1 := Space( 40 )
   cFiltK3 := Space( 40 )
   cRekapKonta := "N"

   Box(, 20, 77 )
   DO WHILE .T.
      @ m_x + 1, m_y + 2 SAY "Radna jedinica (prazno - svi):" GET cidrj ;
         VALID {|| Empty( cIdRj ) .OR. P_RJ( @cIdrj ), if( !Empty( cIdRj ), cIdRj := PadR( cIdRj, 4 ), .T. ), .T. }
      @ m_x + 1, Col() + 2 SAY "sve koje pocinju " GET cpocinju VALID cpocinju $ "DN" PICT "@!"
      @ m_x + 2, m_y + 2 SAY "Konto (prazno - svi):" GET qIdKonto PICT "@!" VALID Empty( qidkonto ) .OR. P_Konto( @qIdKonto )
      @ m_x + 2, Col() + 2 SAY "grupisati konto na broj mjesta" GET nKontoLen PICT "9" valid ( nKontoLen > 0 .AND. nKontoLen < 8 )
      @ m_x + 3, m_y + 2 SAY "Prikaz svih os ( )      /   neotpisanih (N)     / otpisanih   (O) "
      @ m_x + 4, m_y + 2 SAY "/novonabavljenih   (B) / iz proteklih godina (G)" GET cON VALID con $ "ONBG " PICT "@!"
      @ m_x + 5, m_y + 2 SAY "Za sredstvo prikazati vrijednost:"
      @ m_x + 6, m_y + 2 SAY "1 - bez promjena"
      @ m_x + 7, m_y + 2 SAY "2 - osnovni iznos + promjene"
      @ m_x + 8, m_y + 2 SAY "3 - samo promjene           " GET cPromj VALID cpromj $ "123"
      @ m_x + 10, m_y + 2 SAY "1 - prikaz bez uracunate amortizacije i revalor:"
      @ m_x + 11, m_y + 2 SAY "2 - sa uracunatom amortizacijom i revalor      :"
      @ m_x + 12, m_y + 2 SAY "3 - samo amortizacije                          :"
      @ m_x + 13, m_y + 2 SAY "4 - samo revalorizacije                        :"  GET cDodaj VALID cDodaj $ "1234"
      @ m_x + 14, m_y + 2 SAY "Prikazi samo rekapitulaciju konta (D/N)" GET cRekapKonta VALID cRekapKonta $ "DN" PICT "@!"
      @ m_x + 15, m_y + 2 SAY "Pregled za datumski period :" GET cDatPer VALID cdatper $ "DN" PICT "@!"
      @ m_x + 16, m_y + 2 SAY "Filter po sadasnjoj vr.(0-sve,1-samo koja je imaju,2-samo koja je nemaju):" GET cFiltSadVr VALID cFiltSadVr $ "012" PICT "9"
      @ m_x + 17, m_y + 2 SAY "Filter po grupaciji K1:" GET cFiltK1 PICT "@!S20"
      @ m_x + 18, m_y + 2 SAY "Filter po K3:" GET cFiltK3 PICT "@!S10"
      @ m_x + 18, m_y + 30 SAY "Izbaciti(I) / Ubaciti(U)" GET cIzbUbac PICT "@!" VALID cIzbUbac $ "IU"
      @ m_x + 19, m_y + 2 SAY "Prikazati kolonu 'amort.grupa'? D/N" GET cAmoGr VALID cAmoGr $ "DN" PICT "@!"
      READ
      ESC_BCR
      IF cDatPer == "D"
         @ m_x + 20, m_y + 2 SAY "Od datuma " GET dDatOd
         @ m_x + 20, Col() + 2 SAY "do" GET dDatDo
         READ
         ESC_BCR
      ENDIF
      aUsl1 := Parsiraj( cFiltK1, "K1" )
      aUsl2 := Parsiraj( cFiltK3, "K3" )
      IF cIzbUbac == "I"
         aUsl2 := StrTran( aUsl2, "=", "<>" )
      ENDIF
      IF aUsl1 <> NIL
         EXIT
      ENDIF
      IF aUsl2 <> NIL
         EXIT
      ENDIF
   ENDDO
   BoxC()

   // rj na 4 mjesta
   cIdRj := PadR( cIdRj, 4 )

   IF cDatPer == "D"
      select_promj()
      PRIVATE cFilt1 := "DATUM>=" + dbf_quote( dDatOd ) + ".and.DATUM<=" + dbf_quote( dDatDo )
      SET FILTER to &cFilt1
      select_os_sii()
   ENDIF

   IF !Empty( cFiltK1 )
      select_os_sii()
      SET FILTER to &aUsl1
   ENDIF

   IF !Empty( cFiltK3 )
      select_os_sii()
      SET FILTER to &aUsl2
   ENDIF

   IF Empty( qIdKonto )
      qIdKonto := ""
   ENDIF
   IF Empty( cIdrj )
      cIdRj := ""
   ENDIF
   IF cPocinju == "D"
      cIdRj := Trim( cIdRj )
   ENDIF

   os_rpt_default_valute()

   START PRINT CRET

   PRIVATE nStr := 0
   // strana

   SELECT rj
   HSEEK cIdRj

   select_os_sii()

   P_10CPI
   ? gTS + ":", gnFirma

   IF !Empty( cIdrj )
      ? "Radna jedinica:", cIdRj, rj->naz
   ENDIF

   P_COND

   ? _mod_name + ": Pregled sredstava po kontima "

   IF cDodaj == "1"
      ?? "(BEZ uracunate Am. i Rev.)"
   ELSEIF cdodaj == "2"
      ?? "(SA uracunatom Am. i Rev)"
   ELSEIF cdodaj == "3"
      ?? "(samo efekata amortizacije)"
   ELSEIF cdodaj == "4"
      ?? "(samo efekata revalorizacije)"
   ENDIF

   ?? "", PrikazVal(), "    Datum:", os_datum_obracuna()

   IF !Empty( cFiltK1 )
      ? "Filter grupacija K1 pravljen po uslovu: '" + Trim( cFiltK1 ) + "'"
   ENDIF
   IF !Empty( cFiltK3 )
      ? "Filter grupacija K3 pravljen po uslovu: '" + Trim( cFiltK3 ) + "'"
      IF cIzbUbac == "U"
         ?? " sve sto sadrzi."
      ELSE
         ?? " sve sto ne sadrzi."
      ENDIF
   ENDIF


   PRIVATE m := "----- ---------- ----" + IF( cAmoGr == "D", " " + REPL( "-", Len( field->idam ) ), "" ) + " -------- ------------------------------ --- ------" + REPL( " " + REPL( "-", Len( gPicI ) ), 3 )

   IF Empty( cIdrj )
      select_os_sii()
      SET ORDER TO TAG "4"
      // "idkonto+idrj+id"
      SEEK qIdKonto
   ELSE
      select_os_sii()
      SET ORDER TO TAG "3"
      // "idrj+idkonto+id"
      SEEK cIdRj + qIdKonto
   ENDIF

   PRIVATE nRbr := 0

   nDug := 0
   nPot := 0

   os_zagl_konta()

   nA1 := 0
   nA2 := 0
   nUUUKol := 0

   DO WHILE !Eof() .AND. ( idrj = cIdRj .OR. Empty( cIdRj ) )

      cIdSK := Left( idkonto, nKontoLen )
      cNazSKonto := ""

      SELECT konto
      HSEEK cIdSK

      IF Found()
         cNazSKonto := AllTrim( konto->naz )
      ENDIF

      select_os_sii()

      nDug2 := nPot2 := 0
      nUUKol := 0

      DO WHILE !Eof() .AND. ( idrj = cIdRj .OR. Empty( cIdRj ) ) .AND. Left( idkonto, nKontoLen ) == cIdSK

         cIdKonto := idkonto
         cNazKonto := ""

         SELECT konto
         HSEEK cIdKonto

         IF Found()
            cNazKonto := AllTrim( konto->naz )
         ENDIF

         select_os_sii()
         nDug3 := nPot3 := nUKol := 0

         DO WHILE !Eof() .AND. ( idrj = cidrj .OR. Empty( cidrj ) )  .AND. idkonto == cidkonto

            IF datum > os_datum_obracuna()
               // preskoci sredstva van obracuna
               SKIP
               LOOP
            ENDIF

            IF PRow() > RPT_PAGE_LEN
               FF
               os_zagl_konta()
            ENDIF

            IF ( cON == "N" .AND. datotp_prazan() ) .OR. ;
                  ( con == "O"  .AND. !datotp_prazan() ) .OR. ;
                  ( con == "B"  .AND. Year( datum ) = Year( os_datum_obracuna() ) ) .OR. ;
                  ( con == "G"  .AND. Year( datum ) < Year( os_datum_obracuna() ) ) .OR. ;
                  Empty( con )

               fIma := .T.

               IF cDatPer == "D"

                  IF datum >= dDatOd .AND. datum <= dDatDo
                     fIma := .T.
                  ELSE
                     fIma := .F.
                  ENDIF

                  _sr_id := field->id
                  select_promj()
                  // provjeri promjene unutar datuma
                  HSEEK _sr_id

                  DO WHILE !Eof() .AND. _sr_id = field->id
                     IF datum >= dDatOd .AND. datum <= dDatDo
                        fIma := .T.
                     ENDIF
                     SKIP
                  ENDDO
                  select_os_sii()
               ENDIF

               IF cpromj == "3"
                  // ako zelim samo promjene vidi ima li za sr.
                  // uopste promjena
                  _sr_id := field->id
                  _sr_dat_otp := get_datotp()
                  _sr_datum := field->datum

                  select_promj()
                  HSEEK _sr_id
                  fIma := .F.
                  DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
                     IF ( cON == "N" .AND. Empty( _sr_dat_otp ) ) .OR. ;
                           ( con = "O"  .AND. !Empty( _sr_dat_otp ) ) .OR. ;
                           ( con == "B"  .AND. Year( _sr_datum ) = Year( os_datum_obracuna() ) ) .OR. ;
                           ( con == "G"  .AND. Year( field->datum ) < Year( os_datum_obracuna() ) ) .OR. ;
                           Empty( cON )
                        fIma := .T.
                     ENDIF
                     SKIP
                  ENDDO
                  select_os_sii()
               ENDIF

               // ovaj dio nam sad sluzi samo da saznamo ima li sredstvo
               // sadasnju vrijednost
               // ------------------------------------------------------
               lImaSadVr := .F.

               IF cPromj <> "3"
                  IF cDatPer = "N"  .OR. ( cDatPer = "D" .AND. field->datum >= dDatOd .AND. field->datum <= dDatDo )
                     IF cDodaj == "1"
                        nA1 := nabvr
                        nA2 := otpvr
                     ELSEIF cDodaj == "2"
                        nA1 := nabvr + revd
                        nA2 := otpvr + amp + revp
                     ELSEIF cDodaj == "3"
                        nA1 := 0
                        nA2 := amp
                     ELSEIF cDodaj == "4"
                        nA1 := revd
                        nA2 := revp
                     ENDIF
                     IF nA1 - nA2 > 0
                        lImaSadVr := .T.
                     ENDIF
                  ENDIF
                  // prikaz za datumski period, a OS ne pripada tom periodu
               ENDIF

               IF cPromj $ "23"

                  // prikaz promjena
                  _sr_id := field->id
                  _sr_dat_otp := get_datotp()
                  _sr_datum := field->datum

                  select_promj()
                  HSEEK _sr_id
                  DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
                     IF ( cON == "N" .AND. Empty( _sr_dat_otp ) ) .OR. ;
                           ( con = "O"  .AND. !Empty( _sr_dat_otp ) ) .OR. ;
                           ( con == "B"  .AND. Year( _sr_datum ) = Year( os_datum_obracuna() ) ) .OR. ;
                           ( con == "G"  .AND. Year( field->datum ) < Year( os_datum_obracuna() ) ) .OR. ;
                           Empty( con )
                        IF cDodaj == "1"
                           nA1 := nabvr
                           nA2 := otpvr
                        ELSEIF cDodaj == "2"
                           nA1 := nabvr + revd
                           nA2 := otpvr + amp + revp
                        ELSEIF cDodaj == "3"
                           nA1 := 0
                           nA2 := amp
                        ELSEIF cDodaj == "4"
                           nA1 := revd
                           nA2 := revp
                        ENDIF
                        IF nA1 - nA2 > 0
                           lImaSadVr := .T.
                        ENDIF
                     ENDIF
                     SKIP
                  ENDDO
                  select_os_sii()
               ENDIF

               // ispis stavki
               // ------------
               IF cFiltSadVr == "1" .AND. !( lImaSadVr ) .OR. cFiltSadVr == "2" .AND. lImaSadVr
                  SKIP
                  LOOP
               ELSE

                  IF fIma
                     IF cRekapKonta == "N"
                        ? Str( ++nrbr, 4 ) + ".", id, idrj
                     ENDIF
                     IF cRekapKonta == "N" .AND. cAmoGr == "D"
                        ?? "", idam
                     ENDIF
                     IF cRekapKonta == "N"
                        ?? "", datum, naz, jmj, Str( kolicina, 6, 1 )
                     ENDIF
                     nCol1 := PCol() + 1
                  ENDIF

                  IF cPromj <> "3"
                     IF cDatPer = "N"  .OR. ( cDatPer = "D" .AND. datum >= dDatOd .AND. datum <= dDatDo )
                        IF cdodaj == "1"
                           nA1 := nabvr
                           nA2 := otpvr
                        ELSEIF cdodaj == "2"
                           nA1 := nabvr + revd
                           nA2 := otpvr + amp + revp
                        ELSEIF cdodaj == "3"
                           nA1 := 0
                           nA2 := amp
                        ELSEIF cdodaj == "4"
                           nA1 := revd
                           nA2 := revp
                        ENDIF
                        IF cRekapKonta == "N"
                           @ PRow(), PCol() + 1 SAY nA1 * nBBK PICT gpici
                           @ PRow(), PCol() + 1 SAY nA2 * nBBK PICT gpici
                           @ PRow(), PCol() + 1 SAY nA1 * nBBK - nA2 * nBBK PICT gpici
                        ENDIF
                        nDug3 += nA1
                        nPot3 += nA2
                        nUKol += kolicina
                     ENDIF
                     // prikaz za datumski period, a OS ne pripada tom periodu
                  ENDIF

                  IF cPromj $ "23"

                     // prikaz promjena
                     _sr_id := field->id
                     _sr_dat_otp := get_datotp()
                     _sr_datum := field->datum
                     _sr_id_rj := field->idrj
                     _sr_id_am := field->idam

                     select_promj()
                     HSEEK _sr_id

                     DO WHILE !Eof() .AND. field->id == _sr_id .AND. field->datum <= os_datum_obracuna()
                        IF ( cON == "N" .AND. Empty( _sr_dat_otp ) ) .OR. ;
                              ( con = "O"  .AND. !Empty( _sr_dat_otp ) ) .OR. ;
                              ( con == "B"  .AND. Year( _sr_datum ) = Year( os_datum_obracuna() ) ) .OR. ;
                              ( con == "G"  .AND. Year( field->datum ) < Year( os_datum_obracuna() ) ) .OR. ;
                              Empty( con )
                           IF cRekapKonta == "N"
                              ? Space( 5 ), Space( Len( _sr_id ) ), Space( Len( _sr_id_rj ) )
                           ENDIF
                           IF cRekapKonta == "N" .AND. cAmoGr == "D"
                              ?? "", Space( Len( _sr_id_am ) )
                           ENDIF
                           IF cRekapKonta == "N"
                              ?? "", datum, opis
                           ENDIF
                           IF cdodaj == "1"
                              nA1 := nabvr
                              nA2 := otpvr
                           ELSEIF cdodaj == "2"
                              nA1 := nabvr + revd
                              nA2 := otpvr + amp + revp
                           ELSEIF cdodaj == "3"
                              nA1 := 0
                              nA2 := amp
                           ELSEIF cdodaj == "4"
                              nA1 := revd
                              nA2 := revp
                           ENDIF

                           IF cRekapKonta == "N"
                              @ PRow(), nCol1  SAY nA1 * nBBK  PICT gpici
                              @ PRow(), PCol() + 1 SAY nA2 * nBBK  PICT gpici
                              @ PRow(), PCol() + 1 SAY nA1 * nBBK - nA2 * nBBK  PICT gpici
                           ENDIF
                           nDug3 += nA1
                           nPot3 += nA2

                        ENDIF
                        SKIP

                     ENDDO
                     select_os_sii()

                  ENDIF

               ENDIF

            ENDIF
            SKIP
         ENDDO

         IF PRow() > RPT_PAGE_LEN
            FF
            os_zagl_konta()
         ENDIF

         IF cRekapKonta == "N"
            ? m
         ENDIF

         ? " ukupno ", cIdKonto, PadR( cNazKonto, 40 )
         IF cRekapKonta == "D"
            nUUkol += nUKol
            ?? " "
            @ PRow(), PCol() + 1 SAY nUKol
            @ PRow(), PCol() + 1 SAY nDug3 * nBBK PICT gpici
         ELSE
            @ PRow(), nCol1 SAY nDug3 * nBBK PICT gpici
         ENDIF
         @ PRow(), PCol() + 1 SAY npot3 * nBBK PICT gpici
         @ PRow(), PCol() + 1 SAY ndug3 * nBBK - npot3 * nBBK PICT gpici
         IF cRekapKonta == "N"
            ? m
         ENDIF
         nDug2 += nDug3
         nPot2 += nPot3
         IF !Empty( qidkonto )
            EXIT
         ENDIF

      ENDDO

      IF !Empty( qidkonto )
         EXIT
      ENDIF

      IF PRow() > RPT_PAGE_LEN
         FF
         os_zagl_konta()
      ENDIF

      ? m
      ? " UKUPNO ", cIdSk, PadR( cNazSKonto, 40 )

      IF cRekapKonta == "D"
         ?? Space( 5 )
         @ PRow(), PCol() + 1 SAY nUUKol
         @ PRow(), PCol() + 1 SAY nDug2 * nBBK PICT gpici
      ELSE
         @ PRow(), nCol1 SAY nDug2 * nBBK PICT gpici
      ENDIF

      @ PRow(), PCol() + 1 SAY npot2 * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY ndug2 * nBBK - npot2 * nBBK PICT gpici
      nUUUKol += nUUKol
      ? m
      nDug += nDug2
      nPot += nPot2
   ENDDO

   IF Empty( qidkonto )

      IF PRow() > RPT_PAGE_LEN
         FF
         os_zagl_konta()
      ENDIF
      ?
      ? m
      ? " U K U P N O :"
      IF cRekapKonta == "D"
         ?? Space( 44 )
         @ PRow(), PCol() + 1 SAY nUUUKol
         @ PRow(), PCol() + 1 SAY nDug * nBBK PICT gpici
      ELSE
         @ PRow(), nCol1 SAY nDug * nBBK PICT gpici
      ENDIF
      @ PRow(), PCol() + 1 SAY npot * nBBK PICT gpici
      @ PRow(), PCol() + 1 SAY ndug * nBBK - npot * nBBK PICT gpici
      ? m
   ENDIF

   FF

   ENDPRINT

   my_close_all_dbf()

   RETURN


// -------------------------------------
// zaglavlje izvjestaja
// -------------------------------------
FUNCTION os_zagl_konta()

   LOCAL _t_area := Select()

   select_os_sii()

   ?
   P_12CPI
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

   P_COND

   @ PRow(), 125 SAY "Str." + Str( ++nStr, 3 )

   ? m
   ? " Rbr.  Inv.broj   RJ  " + IF( cAmoGr == "D", " " + PadC( "Am.grupa", Len( field->idam ) ), "" ) + "  Datum    Sredstvo                     jmj  kol  " + " " + PadC( "NabVr", Len( gPicI ) ) + " " + PadC( "OtpVr", Len( gPicI ) ) + " " + PadC( "SadVr", Len( gPicI ) )
   ? m

   SELECT ( _t_area )

   RETURN
