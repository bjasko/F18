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


STATIC PicDEM := "99999999.99"
STATIC PicBHD := "99999999.99"
STATIC PicKol := "999999.999"


FUNCTION mat_specifikacija()

   O_ROBA
   O_SIFK
   O_SIFV
   O_TARIFA
   O_MAT_SUBAN
   O_PARTN
   O_KONTO

   cIdFirma := self_organizacija_id()
   qqKonto := qqPartn := Space( 55 )
   cIdTarifa := Space( 6 )
   dDATOD = dDatDO := CToD( "" )
   // cDN:="D"
   cFmt := "2"

   Box( "Spec", 8, 65, .F. )

   @ m_x + 1, m_y + 2 SAY "SPECIFIKACIJA - Izvjestaj formata A3/A4 (1/2)" GET cFmt VALID cFmt $ "12"

   READ

   IF cFmt == "2"
      cFmt := "1"
      @ m_x + 2, m_y + 2 SAY "Iznos u " + ValDomaca() + "/" + ValPomocna() + "(1/2) ?" GET cFmt VALID cFmt $ "12"
      READ
      IF cFmt == "1"
         cFmt := "2"
      ELSE
         cFmt := "3"
      ENDIF
   ENDIF

   IF gNW $ "DR"
      @ m_x + 4, m_y + 2 SAY "Firma "; ?? self_organizacija_id(), "-", self_organizacija_naziv()
   ELSE
      @ m_x + 4, m_y + 2 SAY "Firma: " GET cIdFirma valid {|| p_partner( @cIdFirma ), cidfirma := Left( cidfirma, 2 ), .T. }
   ENDIF

   @ m_x + 5, m_y + 2 SAY KonSeks( "Konta  " ) + " : " GET qqKonto  PICTURE "@S50"
   @ m_x + 6, m_y + 2 SAY "Partner : " GET qqPartn  PICTURE "@S50"
   @ m_x + 7, m_y + 2 SAY "Tarifa (prazno-sve) : " GET cidTarifa  VALID Empty( cidtarifa ) .OR. P_Tarifa( @cIdTarifa )
   @ m_x + 8, m_y + 2 SAY "Datum dokumenta - od datuma:"    GET dDatOd
   @ m_x + 8, Col() + 1 SAY "do:"    GET dDatDo VALID dDatDo >= dDatOd

   DO WHILE .T.

      READ
      ESC_BCR

      aUsl1 := Parsiraj( qqKonto, "IdKonto", "C" )
      aUsl2 := Parsiraj( qqPartn, "IdPartner", "C" )

      IF aUsl1 <> NIL .AND. aUsl2 <> NIL
         EXIT
      ENDIF

   ENDDO

   BoxC()

   ESC_RETURN 0

   cIdFirma := Left( cIdFirma, 2 )

   SELECT mat_suban
   SET ORDER TO TAG "3"

   IF Len( aUsl2 ) == 0
      IF !Empty( dDatOd ) .OR. !Empty( dDatDo )
         SET FILTER TO cIdFirma == IdFirma .AND. Tacno( aUsl1 ) ;
            .AND. dDatOd <= DatDok .AND. dDatDo >= DatDok
      ELSE
         SET FILTER TO cIdFirma == IdFirma .AND. Tacno( aUsl1 )
      ENDIF
   ELSE
      IF !Empty( dDatOd ) .OR. !Empty( dDatDo )
         SET FILTER TO cIdFirma == IdFirma .AND. Tacno( aUsl1 ) ;
            .AND. dDatOd <= DatDok .AND. dDatDo >= DatDok .AND. Tacno( aUsl2 )
      ELSE
         SET FILTER TO cIdFirma == IdFirma .AND. Tacno( aUsl1 ) .AND. Tacno( aUsl2 )
      ENDIF
   ENDIF

   GO TOP

   EOF CRET

   IF cFmt == "1" // A3
      m := "---- ---------- ---------------------------------------- --- ---------- ---------- ---------- ---------- ---------- ---------- ----------- ----------- ----------- ------------ ------------ ------------"
   ELSEIF cFmt == "2"
      m := "---- ---------- ---------------------------------------- --- ---------- ---------- ---------- ----------- ----------- -----------"
   ELSE
      m := "---- ---------- ---------------------------------------- --- ---------- ---------- ---------- ------------ ------------ ------------"
   ENDIF

   START PRINT CRET
   ?
   P_COND

   nCDI := 0
   DO WHILE !Eof()

      cIdKonto := IdKonto
      IF PRow() == 1
         P_COND

         ?? "MAT.P: SPECIFIKACIJA STANJA (U "
         IF cFmt == "1"
            ?? ValDomaca() + "/" + ValPomocna() + ") "
         ELSEIF cFmt == "2"
            ?? ValDomaca() + ") "
         ELSE
            ?? ValDomaca() + ") "
         ENDIF
         IF !Empty( dDatOd ) .OR. !Empty( dDatDo )
            ?? "ZA PERIOD OD", dDatOd, "-", dDatDo
         ENDIF
         ?? "      NA DAN:"
         @ PRow(), PCol() + 1 SAY Date()
         IF !Empty( qqPartn )
            @ PRow() + 1, 0 SAY "Kriterij za partnera:"; ?? Trim( qqPartn )
         ENDIF
         IF !Empty( cidtarifa )
            @ PRow() + 1, 0 SAY "Tarifa: "; ?? cidtarifa
         ENDIF
         @ PRow() + 1, 0 SAY "FIRMA:"
         @ PRow(), PCol() + 1 SAY cIdFirma
         SELECT PARTN
         HSEEK cIdFirma
         @ PRow(), PCol() + 1 SAY AllTrim( naz )
         @ PRow(), PCol() + 1 SAY AllTrim( naz2 )
         @ PRow() + 1, 0 SAY KonSeks( "KONTO" ) + ":"
         @ PRow(), PCol() + 1 SAY cIdKonto
         SELECT konto
         HSEEK cidkonto
         @ PRow(), PCol() + 1 SAY AllTrim( naz )
         SELECT mat_suban
         ?  m
         IF cFmt == "1"
            ? "*R. *  SIFRA   *       N A Z I V                        *J. *   ZADNJA *  ZADNJA  *  ZADNJA  *       K O L I C I N A          *     V R I J E D N O S T    " + ValDomaca() + "   *        V R I J E D N O S T   " + ValPomocna() + "   *"
            ? " Br.                                                    *   *    NC    *    VPC   *   MPC     ------------------------------- ------------------------------------ --------------------------------------"
            ? "*   *          *                                        *MJ.*          *          *          *   ULAZ   *  IZLAZ   *  STANJE  *  DUGUJE   * POTRAZUJE *   SALDO   *  DUGUJE    *  POTRAZUJE *  SALDO    *"
         ELSEIF cFmt == "2"
            ? "*R. *  SIFRA   *       N A Z I V                        *J. *       K O L I C I N A          *     V R I J E D N O S T          *"
            ? "*Br.*                                                       -------------------------------- ------------------------------------"
            ? "*   *          *                                        *MJ.*   ULAZ   *  IZLAZ   *  STANJE  *  DUGUJE   * POTRAZUJE *  SALDO   *"
         ELSEIF cFmt == "3"
            ? "*R. *  SIFRA   *       N A Z I V                        *J. *       K O L I C I N A          *        V R I J E D N O S T          *"
            ? "*Br.*                                                       -------------------------------- ---------------------------------------"
            ? "*   *          *                                        *MJ.*   ULAZ   *  IZLAZ   *  STANJE  *  DUGUJE    *  POTRAZUJE *  SALDO    *"
         ENDIF
         ?  m
      ENDIF

      B := 0

      nUkDugI := 0
      nUkPotI := 0
      nUkDugI2 := 0
      nUkPotI2 := 0
      nUKolUlaz := 0
      nUKolIzlaz := 0
      nUKolStanje := 0

      DO WHILE  !Eof() .AND.  cIdKonto == IdKonto

         NovaStrana()

         SELECT mat_suban
         cIdRoba := IdRoba
         SELECT roba
         HSEEK cidroba
         SELECT mat_suban
         IF !Empty( cIdTarifa )
            IF roba->idtarifa <> cIdtarifa
               SKIP
               LOOP
            ENDIF
         ENDIF
         nDugI := nPotI := nUlazK := nIzlazK := 0
         nDugI2 := nPotI2 := nUlazK2 := nIzlazK2 := 0
         DO WHILE !Eof() .AND. cIdkonto == IdKonto .AND. cIdRoba = IdRoba
            IF U_I = "1"
               nUlazK += Kolicina
            ELSE
               nIzlazK += Kolicina
            ENDIF
            IF D_P = "1"
               nDugI += Iznos
               nDugI2 += Iznos2
            ELSE
               nPotI += Iznos
               nPotI2 += Iznos2
            ENDIF
            SKIP
         ENDDO // IdRoba

         SELECT roba
         cRoba := PadR( field->naz, 40 )
         cJmj := field->jmj


         nSaldoK := nUlazK - nIzlazK
         nSaldoI := nDugI - nPotI
         nSaldoK2 := nUlazK2 - nIzlazK2
         nSaldoI2 := nDugI2 - nPotI2

         @ PRow() + 1, 0 SAY ++B PICTURE '9999'
         @ PRow(), PCol() + 1 SAY cIdRoba
         @ PRow(), PCol() + 1 SAY cRoba
         @ PRow(), PCol() + 1 SAY cjmj

         IF cFmt == "1"
            @ PRow(), PCol() + 1 SAY NC   PICTURE "999999.999"
            @ PRow(), PCol() + 1 SAY VPC  PICTURE "999999.999"
            @ PRow(), PCol() + 1 SAY MPC  PICTURE "999999.999"
         ENDIF

         nCDI := PCol()

         @ PRow(), PCol() + 1 SAY nUlazK PICTURE picKol
         @ PRow(), PCol() + 1 SAY nIzlazK PICTURE picKol
         @ PRow(), PCol() + 1 SAY nSaldoK PICTURE picKol

         IF cFmt $ "12"
            @ PRow(), PCol() + 1 SAY nDugI PICTURE PicDEM
            @ PRow(), PCol() + 1 SAY nPotI PICTURE PicDEM
            @ PRow(), PCol() + 1 SAY nSaldoI PICTURE PicDEM
         ENDIF
         IF cFmt $ "13"
            @ PRow(), PCol() + 1 SAY nDugI2 PICTURE PicBHD
            @ PRow(), PCol() + 1 SAY nPotI2 PICTURE PicBHD
            @ PRow(), PCol() + 1 SAY nSaldoI2 PICTURE PicBHD
         ENDIF

         nUKolUlaz += nUlazK
         nUKolIzlaz += nIzlazK
         nUKolStanje += nSaldoK

         nUkDugI += nDugI
         nUkPotI += nPotI
         nUkDugI2 += nDugI2
         nUkPotI2 += nPotI2

         nDugI := nPotI := nUlazK := nIzlazK := 0
         nDugI2 := nPotI2 := nUlazK2 := nIzlazK2 := 0

         SELECT mat_suban
      ENDDO // konto

      ? m
      ? "UKUPNO ZA:" + cIdKonto

      @ PRow(), nCDI SAY ""

      @ PRow(), PCol() + 1 SAY nUKolUlaz PICTURE PicKol
      @ PRow(), PCol() + 1 SAY nUKolIzlaz PICTURE PicKol
      @ PRow(), PCol() + 1 SAY nUKolStanje PICTURE PicKol

      IF cFmt $ "12"
         @ PRow(), PCol() + 1 SAY nUkDugI PICTURE PicDEM
         @ PRow(), PCol() + 1 SAY nUkPotI PICTURE PicDEM
         @ PRow(), PCol() + 1 SAY nUkDugI - nUkPotI PICTURE PicDEM
      ENDIF

      IF cFmt $ "13"
         @ PRow(), PCol() + 1 SAY nUkDugI2          PICTURE PicBHD
         @ PRow(), PCol() + 1 SAY nUkPotI2          PICTURE PicBHD
         @ PRow(), PCol() + 1 SAY nUkDugI2 - nUkPotI2 PICTURE PicBHD
      ENDIF
      ? m

      FF

   ENDDO
   // firma

   ENDPRINT

   my_close_all_dbf()

   RETURN



FUNCTION KonSekS( cNaz )
   RETURN if( gSekS == "D", "PREDMET", cNaz )



FUNCTION IArtPoPogonima()

   O_PARTN         // pogoni
   O_ROBA          // artikli
   O_SIFK
   O_SIFV
   O_MAT_SUBAN         // dokumenti

   cIdRoba := Space( Len( ROBA->id ) )
   dOd := CToD( "" )
   dDo := Date()
   gOstr := "D"; gTabela := 1
   cSaIznosima := "D"
   qqPartner := ""
   // artikal : ulaz, izlaz, cijena

   O_PARAMS
   PRIVATE cSection := "7", cHistory := " ", aHistory := {}
   Params1()
   RPar( "c1", @cIdRoba )
   RPar( "c2", @dOd )
   RPar( "c3", @dDo )
   RPar( "c4", @cSaIznosima )
   RPar( "c5", @qqPartner )

   qqPartner := PadR( qqPartner, 60 )

   Box(, 7, 70 )
   @ m_x + 2, m_y + 2 SAY "Artikal (prazno-svi): " GET cIdRoba VALID Empty( cIdRoba ) .OR. P_Roba( @cIdRoba, 2, 24 ) PICT "@!"
   @ m_x + 3, m_y + 2 SAY "Za period od:" GET dOd
   @ m_x + 3, Col() + 2 SAY "do:" GET dDo
   @ m_x + 4, m_y + 2 SAY "Prikazati iznose? (D/N)" GET cSaIznosima VALID cSaIznosima $ "DN" PICT "@!"
   @ m_x + 5, m_y + 2 SAY "Uslov za pogone (prazno-svi)" GET qqPartner PICT "@S30"
   DO WHILE .T.
      READ; ESC_BCR
      aUsl1 := Parsiraj( qqPartner, "IDPARTNER", "C" )
      IF aUsl1 <> NIL; EXIT; ENDIF
   ENDDO
   BoxC()

   qqPartner := Trim( qqPartner )

   IF Params2()
      WPar( "c1", cIdRoba )
      WPar( "c2", dOd )
      WPar( "c3", dDo )
      WPar( "c4", cSaIznosima )
      WPar( "c5", qqPartner )
   ENDIF
   SELECT params; USE

   SELECT mat_suban

   IF Empty( cIdRoba )

      // svi artikli

      SET ORDER TO TAG "idroba"

      cFilt := "DATDOK>=dOd .and. DATDOK<=dDo "
      IF !Empty( qqPartner )
         cFilt += ( ".and." + aUsl1 )
      ENDIF

      SET FILTER to &cFilt
      GO TOP

      IF Eof()
         Msg( "Ne postoje trazeni podaci...", 6 )
         my_close_all_dbf()
         RETURN
      ENDIF

      START PRINT CRET

      PRIVATE cIdRoba := "", cArtikal := "", cJMJ := "", nRBr := 0
      PRIVATE nUlaz := 0, nIzlaz := 0, nKol := 0, nDuguje := 0, nPotrazuje := 0, nSaldo := 0

      aKol := { { "R.BR.", {|| Str( nRBr, 4 ) + "." }, .F., "C", 5, 0, 1, ++nKol }, ;
         { "SIFRA", {|| cIdRoba        }, .F., "C", 10, 0, 1, ++nKol }, ;
         { "NAZIV ARTIKLA", {|| cArtikal       }, .F., "C", 40, 0, 1, ++nKol }, ;
         { "J.MJ.", {|| PadC( cJMJ, 5 )   }, .F., "C", 5, 0, 1, ++nKol }, ;
         { "ULAZ " + cJMJ, {|| nUlaz          }, .F., "N", 12, 2, 1, ++nKol }, ;
         { "IZLAZ " + cJMJ, {|| nIzlaz         }, .F., "N", 12, 2, 1, ++nKol } }

      IF cSaIznosima == "D"
         AAdd( aKol, { "DUGUJE", {|| nDuguje    }, .T., "N", 12, 2, 1, ++nKol } )
         AAdd( aKol, { "POTRAZUJE", {|| nPotrazuje }, .T., "N", 12, 2, 1, ++nKol } )
         AAdd( aKol, { "SALDO", {|| nSaldo     }, .T., "N", 12, 2, 1, ++nKol } )
      ENDIF

      P_10CPI
      ?? self_organizacija_naziv()
      ?
      ? "DATUM  : " + SrediDat( Date() )
      ? "POGONI : " + IF( Empty( qqPartner ), "SVI", Trim( qqPartner ) )

      print_lista_2( aKol, {|| FSvaki2s() },, gTabela,, ;
         , "Specifikacija svih artikala - pregled za period od " + DToC( dod ) + " do " + DToC( ddo ), ;
         {|| FFor2s() }, IF( gOstr == "D",, -1 ),,,,, )
      FF
      ENDPRINT

   ELSE

      // jedan artikal
      SET ORDER TO TAG "idpartn"

      cFilt  := "IDROBA==cIdRoba .and. DATDOK>=dOd .and. DATDOK<=dDo "
      IF !Empty( qqPartner )
         cFilt += ( ".and." + aUsl1 )
      ENDIF
      SET FILTER to &cFilt
      GO TOP

      IF Eof()
         Msg( "Ne postoje trazeni podaci...", 6 )
         my_close_all_dbf()
         RETURN
      ENDIF

      START PRINT CRET

      PRIVATE cIdPartner := "", cNPartnera := ""
      PRIVATE nUlaz := 0, nIzlaz := 0, nKol := 0, nDuguje := 0, nPotrazuje := 0, nSaldo := 0

      cJMJ := "(" + ROBA->jmj + ")"

      aKol := { { "SIFRA", {|| cIdPartner         }, .F., "C", 6, 0, 1, ++nKol }, ;
         { "PARTNER/MJESTO TROSKA", {|| cNPartnera }, .F., "C", 50, 0, 1, ++nKol }, ;
         { "ULAZ " + cJMJ, {|| nUlaz              }, .T., "N", 12, 2, 1, ++nKol }, ;
         { "IZLAZ " + cJMJ, {|| nIzlaz             }, .T., "N", 12, 2, 1, ++nKol } }

      IF cSaIznosima == "D"
         AAdd( aKol, { "DUGUJE", {|| nDuguje    }, .T., "N", 12, 2, 1, ++nKol } )
         AAdd( aKol, { "POTRAZUJE", {|| nPotrazuje }, .T., "N", 12, 2, 1, ++nKol } )
         AAdd( aKol, { "SALDO", {|| nSaldo     }, .T., "N", 12, 2, 1, ++nKol } )
      ENDIF

      P_10CPI
      ?? self_organizacija_naziv()
      ?
      ? "DATUM  : " + SrediDat( Date() )
      ? "ARTIKAL: " + cIdRoba + " - " + ROBA->naz

      print_lista_2( aKol, {|| FSvaki1s() },, gTabela,, ;
         , "Specifikacija artikla - pregled po pogonima za period od " + DToC( dod ) + " do " + DToC( ddo ), ;
         {|| FFor1s() }, IF( gOstr == "D",, -1 ),,,,, )
      FF
      ENDPRINT
   ENDIF

   CLOSERET

STATIC FUNCTION FFor1s()

   cIdPartner := idpartner
   cNPartnera := Ocitaj( F_PARTN, idpartner, "TRIM(naz)+' '+TRIM(naz2)" )
   nUlaz := nIzlaz := nDuguje := nPotrazuje := nSaldo := 0
   DO WHILE !Eof() .AND. idpartner == cIdPartner
      IF u_i == "1"
         nDuguje += iznos
         nSaldo  += iznos
         nUlaz   += kolicina
      ELSE
         nPotrazuje += iznos
         nSaldo     -= iznos
         nIzlaz     += kolicina
      ENDIF
      SKIP 1
   ENDDO
   SKIP -1

   RETURN .T.


STATIC FUNCTION FSvaki1s()
   RETURN


STATIC FUNCTION FFor2s()

   LOCAL nArr := Select()

   ++nRBr
   cIdRoba := idroba
   SELECT ROBA; SEEK cIdRoba
   cArtikal := Trim( naz )
   cJMJ     := Trim( jmj )
   SELECT ( nArr )
   nUlaz := nIzlaz := nDuguje := nPotrazuje := nSaldo := 0
   DO WHILE !Eof() .AND. idroba == cIdRoba
      IF u_i == "1"
         nDuguje += iznos
         nSaldo  += iznos
         nUlaz   += kolicina
      ELSE
         nPotrazuje += iznos
         nSaldo     -= iznos
         nIzlaz     += kolicina
      ENDIF
      SKIP 1
   ENDDO
   SKIP -1

   RETURN .T.


STATIC FUNCTION FSvaki2s()
   RETURN
