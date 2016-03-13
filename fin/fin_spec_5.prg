#include "f18.ch"

/*! \fn PregNDP()
 *  \brief Pregled novih dugovanja i potrazivanja
 */
FUNCTION PregNDP()

   picBHD := FormPicL( "9 " + gPicBHD, 17 )
   PRIVATE cDP := "1"
   PRIVATE cSortPar := "S"
   PRIVATE cMjestoPar := Space( 80 )

   O_PARTN
   __par_len := Len( partn->id )

   O_KONTO

   Box( "#PREGLED NOVIH DUGOVANJA/POTRAZIVANJA", 15, 72 )

   IF gNW == "D"
      cIdFirma := gfirma
      @ m_x + 1, m_y + 2 SAY "Firma "; ?? gFirma, "-", gNFirma
   ELSE
      cidfirma := "10"
      @ m_x + 1, m_y + 2 SAY "Firma: " GET cIdFirma valid {|| P_Firma( @cIdFirma ), cidfirma := Left( cidfirma, 2 ), .T. }
   ENDIF
   @ m_x + 2, m_y + 2 SAY "Dugovanja/Potrazivanja (1/2):" GET cDP VALID cDP $ "12"
   READ
   ESC_BCR

   IF cDP == "2"
      cIdkonto := PadR( "5410", 7 )
   ELSE
      cIdkonto := PadR( "2110", 7 )
   ENDIF

   dDatOd := Date() - 7
   dDatDo := Date()

   PRIVATE cPrik := "2"
   PRIVATE cDinDem := "1"
   PRIVATE cPG := "D"
   PRIVATE cPoRP := "2"

   @ m_x + 3, m_y + 2 SAY "Konto:" GET cIdkonto VALID p_kontoFin( @cidkonto )
   @ m_x + 5, m_y + 2 SAY "Period:" GET dDatOd
   @ m_x + 5, Col() + 2 SAY "do" GET dDatDo VALID dDatDo >= dDatOd
   IF gVar1 == "0"
      @ m_x + 6, m_y + 2 SAY "Prikaz " + AllTrim( ValDomaca() ) + "/" + AllTrim( ValPomocna() ) + " (1/2)"  GET cDinDEM VALID cdindem $ "12"
   ENDIF
   @ m_x + 8, m_y + 2 SAY "Prikaz: (1) stavki kod kojih nije bilo promjena u toku tekuce godine"
   @ m_x + 9, m_y + 2 SAY "        (2) stavki kod kojih nije bilo promjena u zadanom periodu"
   @ m_x + 10, m_y + 2 SAY "        (3) samo stavki kod kojih je bilo promjena u zadanom periodu" GET cPrik VALID cprik $ "123"
   @ m_x + 12, m_y + 2 SAY "Prikazi mjesto partnera (D/N)" GET cPG VALID cPG $ "DN"

   IF gRj == "D"
      @ m_x + 13, m_y + 2 SAY "1-po RJ  ili  2-po partnerima (1/2)" GET cPoRP VALID cPoRP $ "12"
   ENDIF

   IF ( cPoRP == "2" ) // po partnerima
      @ m_x + 14, m_y + 2 SAY "Sortiranje partnera (S-po sifri,N-po nazivu)" GET cSortPar VALID cSortPar $ "SN" PICT "@!"
      @ m_x + 15, m_y + 2 SAY "Uslov za mjesto partnera (prazno-sva)" GET cMjestoPar PICT "@S25"
   ENDIF

   DO WHILE .T.
      READ
      ESC_BCR
      aUslMP := Parsiraj( cMjestoPar, "partn->mjesto" )
      IF aUslMP <> nil
         EXIT
      ENDIF
   ENDDO

   BoxC()

   O_SUBAN

   IF cPoRP == "1"
      O_RJ
      SELECT suban
      INDEX ON idfirma + idkonto + idrj + DToS( datdok ) TO SUBSUB
      SET ORDER TO TAG "SUBSUB"
   ELSE
      IF cSortPar == "N" .OR. !Empty( cMjestoPar )
         SET RELATION TO suban->idpartner into partn
      ENDIF
      IF cSortPar == "N"
         INDEX ON idfirma + idkonto + PadR( partn->naz, 25 ) + idpartner + DToS( datdok ) TO SUBSUB
         SET ORDER TO TAG "SUBSUB"
      ENDIF
      IF !Empty( cMjestoPar )
         SET FILTER to &aUslMP
      ENDIF
   ENDIF

   HSEEK cidfirma + cidkonto
   EOF CRET

   IF cPG == "D"
      m := Replicate( "-", __par_len )
      m += " "
      m += Replicate( "-", 25 )
      m += " --------------- ------------------ ----------------- ----------------- ----------------- ---------------"
   ELSE
      m := Replicate( "-", __par_len )
      m += " "
      m += Replicate( "-", 25 )
      m += " ------------------ ----------------- ----------------- ----------------- -------------------"
   ENDIF

   START PRINT CRET
   zagl9()
   PRIVATE nTPS1 := nTPS2 := nTS1 := nTS2 := nTT1 := nTT2 := 0
   nCol1 := 60

   DO WHILE cidfirma == idfirma .AND. !Eof() .AND. cidkonto == idkonto

      IF cPoRP == "1"
         cIdPartner := idrj
      ELSE
         cIdPartner := idpartner
      ENDIF

      nPS1 := 0
      nPS2 := 0

      fYear := .F.

      DO WHILE cidfirma == idfirma .AND. !Eof() .AND. cidkonto == idkonto .AND. IF( cPoRP == "1", idrj, idpartner ) == cidpartner .AND. datdok < dDatOd

         IF d_p == "1"
            nPS1 += iznosbhd
            nPS2 += iznosdem
         ELSE
            nPS1 -= iznosbhd
            nPS2 -= iznosdem
         ENDIF

         IF Year( datdok ) == Year( Date() )
            // bilo je prometa u toku godine
            fYear := .T.
         ENDIF

         SKIP 1
      ENDDO

      nS1 := nS2 := 0
      nT1 := nT2 := 0

      DO WHILE cidfirma == idfirma .AND. !Eof() .AND. cidkonto == idkonto .AND. IF( cPoRP == "1", idrj, idpartner ) == cidpartner .AND. datdok <= dDatDo
         IF cDP == "1" // duznici
            IF d_p == "1"
               nS1 += iznosbhd
               nS2 += iznosdem
            ELSE
               nT1 += iznosbhd
               nT2 += iznosdem
            ENDIF
         ELSE // dobavljaci
            IF d_p == "1"
               nT1 += iznosbhd
               nT2 += iznosdem
            ELSE
               nS1 += iznosbhd
               nS2 += iznosdem
            ENDIF
         ENDIF

         IF Year( datdok ) == Year( Date() )  // bilo je prometa u toku godine
            fYear := .T.
         ENDIF

         SKIP 1
      ENDDO

      DO WHILE cidfirma == idfirma .AND. !Eof() .AND. cidkonto == idkonto .AND. IF( cPoRP == "1", idrj, idpartner ) == cidpartner
         SKIP 1
      ENDDO

      IF cDP == "2"  // potrazivanja
         nPS1 := -nPs1
         nPS2 := -nPs2
      ENDIF

      IF ( cPrik == "1" ) .OR. ( cPrik == "2" .AND. fyear ) .OR. ( cPrik == "3" .AND. ( ns1 <> 0 .OR. ns2 <> 0 .OR. nt1 <> 0 .OR. nt2 <> 0 ) )

         IF cPoRP == "1"
            SELECT rj
            HSEEK cidpartner
            SELECT suban
         ELSE
            SELECT partn
            HSEEK cidpartner
            SELECT suban
         ENDIF

         IF PRow() > 60 + dodatni_redovi_po_stranici()
            FF
            zagl9()
         ENDIF

         ? cIdPartner + " "

         IF cPoRP == "1"
            ?? PadR( RJ->naz, 36 )
         ELSE

            IF cPG == "N"
               ?? PadR( partn->naz, 25 )
            ELSE
               ?? Left ( PARTN->Naz, 25 ), Left ( PARTN->Mjesto, 15 )
            ENDIF

         ENDIF

         nCol1 := PCol() + 1
         IF cDinDEM == "1"
            @ PRow(), PCol() + 1 SAY nPS1 PICT picbhd
            @ PRow(), PCol() + 1 SAY nS1 PICT picbhd
            @ PRow(), PCol() + 1 SAY nT1 PICT picbhd
            @ PRow(), PCol() + 1 SAY nPS1 + nS1 - nT1 PICT picbhd
         ELSE
            @ PRow(), PCol() + 1 SAY nPS2 PICT picbhd
            @ PRow(), PCol() + 1 SAY nS2 PICT picbhd
            @ PRow(), PCol() + 1 SAY nT2 PICT picbhd
            @ PRow(), PCol() + 1 SAY nPS2 + nS2 - nT2 PICT picbhd
         ENDIF

         @ PRow(), PCol() + 2 SAY iif ( cPG = "N", "__________________", "______________" )
         nTPS1 += nPS1
         nTPS2 += nPS2
         nTS1 += nS1
         nTS2 += nS2
         nTT1 += nT1
         nTT2 += nT2
      ENDIF

   ENDDO

   ? m
   ? "  UKUPNO:"
   IF cDinDEM == "1"
      @ PRow(), nCol1 SAY nTPS1 PICT picbhd
      @ PRow(), PCol() + 1 SAY nTS1 PICT picbhd
      @ PRow(), PCol() + 1 SAY nTT1 PICT picbhd
      @ PRow(), PCol() + 1 SAY nTPS1 + nTS1 - nTT1 PICT picbhd
   ELSE
      @ PRow(), ncol1 SAY nTPS2 PICT picbhd
      @ PRow(), PCol() + 1 SAY nTS2 PICT picbhd
      @ PRow(), PCol() + 1 SAY nTT2 PICT picbhd
      @ PRow(), PCol() + 1 SAY nTPS2 + nTS2 - nTT2 PICT picbhd
   ENDIF
   ? m
   FF
   ENDPRINT

   RETURN




/*! \fn Zagl9()
 *  \brief Zaglavlje pregleda novih dugovanja i potrazivanja
 *  \param
 */
FUNCTION Zagl9()

   LOCAL nTArea := Select()

   ?
   P_COND
   ?? Space( 35 )

   B_ON

   ?? "PREGLED ", iif( cDP == "1", "DUGOVANJA", "POTRA�IVANJA" )
   ?? ", ZA PERIOD ", dDatOd, "-", dDatDo

   // uzmi konto
   SELECT konto
   HSEEK cIdKonto
   SELECT ( nTArea )

   ? Space( 2 )
   ?? AllTrim( cIdKonto ), ":", AllTrim( konto->naz )

   IF cPoRP == "1"
      ? Space( 2 )
      ?? "PO RADNIM JEDINICAMA"
   ENDIF

   B_OFF

   IF !Empty( cMjestoPar )
      ? "Zadan je uslov za mjesto partnera:'" + Trim( cMjestoPar ) + "'"
   ENDIF

   IF cDP == "1"

      ? m

      IF cPoRP == "1"

         ? Space( __par_len ) + "  Naziv                                 Prethodno           Novo             Napla�eno         Sada�nje          Napomena"
         ? Space( __par_len ) + "                                          stanje          potra�ivanje                           stanje"

      ELSEIF cPG == "N"

         ? Space( __par_len ) + "    Naziv                     Prethodno           Novo             Napla�eno         Sadasnje          Napomena"
         ? Space( __par_len ) + "                               stanje          potra�ivanje                           stanje"

      ELSE

         ? Space( __par_len ) + "  Naziv                  Mjesto         Prethodno           Novo             Napla�eno         Sada�nje          Napomena"
         ? Space( __par_len ) + "                                          stanje          potra�ivanje                           stanje"

      ENDIF

      ? m
   ELSE
      ? m
      IF cPoRP == "1"
         ? Space( __par_len ) + "  Naziv                                 Prethodno           Prispjelo         Placeno          Sada�nje          Napomena"
         ? Space( __par_len ) + "                                          stanje                                                 stanje"
      ELSEIF cPG == "N"
         ? Space( __par_len ) + "  Naziv                       Prethodno         Prispjelo          Placeno          Sada�nje          Napomena"
         ? Space( __par_len ) + "                                stanje                                               stanje"
      ELSE
         ? Space( __par_len ) + "  Naziv                  Mjesto         Prethodno           Prispjelo         Placeno          Sada�nje          Napomena"
         ? Space( __par_len ) + "                                          stanje                                                 stanje"
      ENDIF
      ? m
   ENDIF

   RETURN
